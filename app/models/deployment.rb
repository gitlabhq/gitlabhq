# frozen_string_literal: true

class Deployment < ApplicationRecord
  include AtomicInternalId
  include IidRoutes
  include AfterCommitQueue

  belongs_to :project, required: true
  belongs_to :environment, required: true
  belongs_to :cluster, class_name: 'Clusters::Cluster', optional: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  has_internal_id :iid, scope: :project, init: ->(s) do
    Deployment.where(project: s.project).maximum(:iid) if s&.project
  end

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  scope :for_environment, -> (environment) { where(environment_id: environment) }

  state_machine :status, initial: :created do
    event :run do
      transition created: :running
    end

    event :succeed do
      transition any - [:success] => :success
    end

    event :drop do
      transition any - [:failed] => :failed
    end

    event :cancel do
      transition any - [:canceled] => :canceled
    end

    before_transition any => [:success, :failed, :canceled] do |deployment|
      deployment.finished_at = Time.now
    end

    after_transition any => :success do |deployment|
      deployment.run_after_commit do
        Deployments::SuccessWorker.perform_async(id)
      end
    end

    after_transition any => [:success, :failed, :canceled] do |deployment|
      deployment.run_after_commit do
        Deployments::FinishedWorker.perform_async(id)
      end
    end
  end

  enum status: {
    created: 0,
    running: 1,
    success: 2,
    failed: 3,
    canceled: 4
  }

  def self.last_for_environment(environment)
    ids = self
      .for_environment(environment)
      .select('MAX(id) AS id')
      .group(:environment_id)
      .map(&:id)
    find(ids)
  end

  def commit
    project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def short_sha
    Commit.truncate_sha(sha)
  end

  # Deprecated - will be replaced by a persisted cluster_id
  def deployment_platform_cluster
    environment.deployment_platform&.cluster
  end

  def execute_hooks
    deployment_data = Gitlab::DataBuilder::Deployment.build(self)
    project.execute_services(deployment_data, :deployment_hooks)
  end

  def last?
    self == environment.last_deployment
  end

  def create_ref
    project.repository.create_ref(ref, ref_path)
  end

  def invalidate_cache
    environment.expire_etag_cache
  end

  def manual_actions
    @manual_actions ||= deployable.try(:other_manual_actions)
  end

  def scheduled_actions
    @scheduled_actions ||= deployable.try(:other_scheduled_actions)
  end

  def includes_commit?(commit)
    return false unless commit

    project.repository.ancestor?(commit.id, sha)
  end

  def update_merge_request_metrics!
    return unless environment.update_merge_request_metrics? && success?

    merge_requests = project.merge_requests
                     .joins(:metrics)
                     .where(target_branch: self.ref, merge_request_metrics: { first_deployed_to_production_at: nil })
                     .where("merge_request_metrics.merged_at <= ?", finished_at)

    if previous_deployment
      merge_requests = merge_requests.where("merge_request_metrics.merged_at >= ?", previous_deployment.finished_at)
    end

    # Need to use `map` instead of `select` because MySQL doesn't allow `SELECT`ing from the same table
    # that we're updating.
    merge_request_ids =
      if Gitlab::Database.postgresql?
        merge_requests.select(:id)
      elsif Gitlab::Database.mysql?
        merge_requests.map(&:id)
      end

    MergeRequest::Metrics
      .where(merge_request_id: merge_request_ids, first_deployed_to_production_at: nil)
      .update_all(first_deployed_to_production_at: finished_at)
  end

  def previous_deployment
    @previous_deployment ||=
      project.deployments.joins(:environment)
      .where(environments: { name: self.environment.name }, ref: self.ref)
      .where.not(id: self.id)
      .take
  end

  def stop_action
    return unless on_stop.present?
    return unless manual_actions

    @stop_action ||= manual_actions.find_by(name: on_stop)
  end

  def finished_at
    read_attribute(:finished_at) || legacy_finished_at
  end

  def deployed_at
    return unless success?

    finished_at
  end

  def formatted_deployment_time
    deployed_at&.to_time&.in_time_zone&.to_s(:medium)
  end

  private

  def ref_path
    File.join(environment.ref_path, 'deployments', iid.to_s)
  end

  def legacy_finished_at
    self.created_at if success? && !read_attribute(:finished_at)
  end
end
