# frozen_string_literal: true

class Deployment < ApplicationRecord
  include AtomicInternalId
  include IidRoutes
  include AfterCommitQueue
  include UpdatedAtFilterable
  include Gitlab::Utils::StrongMemoize

  belongs_to :project, required: true
  belongs_to :environment, required: true
  belongs_to :cluster, class_name: 'Clusters::Cluster', optional: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true, optional: true # rubocop:disable Cop/PolymorphicAssociations
  has_many :deployment_merge_requests

  has_many :merge_requests,
    through: :deployment_merge_requests

  has_internal_id :iid, scope: :project, init: ->(s) do
    Deployment.where(project: s.project).maximum(:iid) if s&.project
  end

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  scope :for_environment, -> (environment) { where(environment_id: environment) }

  scope :visible, -> { where(status: %i[running success failed canceled]) }

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

  def self.distinct_on_environment
    order('environment_id, deployments.id DESC')
      .select('DISTINCT ON (environment_id) deployments.*')
  end

  def self.find_successful_deployment!(iid)
    success.find_by!(iid: iid)
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

  def playable_build
    strong_memoize(:playable_build) do
      deployable.try(:playable?) ? deployable : nil
    end
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

    MergeRequest::Metrics
      .where(merge_request_id: merge_requests.select(:id), first_deployed_to_production_at: nil)
      .update_all(first_deployed_to_production_at: finished_at)
  end

  def previous_deployment
    @previous_deployment ||=
      project.deployments.joins(:environment)
      .where(environments: { name: self.environment.name }, ref: self.ref)
      .where.not(id: self.id)
      .order(id: :desc)
      .take
  end

  def previous_environment_deployment
    project
      .deployments
      .success
      .joins(:environment)
      .where(environments: { name: environment.name })
      .where.not(id: self.id)
      .order(id: :desc)
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

  def deployed_by
    # We use deployable's user if available because Ci::PlayBuildService
    # does not update the deployment's user, just the one for the deployable.
    # TODO: use deployment's user once https://gitlab.com/gitlab-org/gitlab-foss/issues/66442
    # is completed.
    deployable&.user || user
  end

  def link_merge_requests(relation)
    select = relation.select(['merge_requests.id', id]).to_sql

    # We don't use `Gitlab::Database.bulk_insert` here so that we don't need to
    # first pluck lots of IDs into memory.
    DeploymentMergeRequest.connection.execute(<<~SQL)
      INSERT INTO #{DeploymentMergeRequest.table_name}
      (merge_request_id, deployment_id)
      #{select}
    SQL
  end

  # Changes the status of a deployment and triggers the correspinding state
  # machine events.
  def update_status(status)
    case status
    when 'running'
      run
    when 'success'
      succeed
    when 'failed'
      drop
    when 'canceled'
      cancel
    else
      raise ArgumentError, "The status #{status.inspect} is invalid"
    end
  end

  private

  def ref_path
    File.join(environment.ref_path, 'deployments', iid.to_s)
  end

  def legacy_finished_at
    self.created_at if success? && !read_attribute(:finished_at)
  end
end

Deployment.prepend_if_ee('EE::Deployment')
