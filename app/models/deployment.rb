class Deployment < ActiveRecord::Base
  include AtomicInternalId

  belongs_to :project, required: true
  belongs_to :environment, required: true
  belongs_to :user
  belongs_to :deployable, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.deployments&.maximum(:iid) }

  validates :sha, presence: true
  validates :ref, presence: true

  delegate :name, to: :environment, prefix: true

  after_create :create_ref
  after_create :invalidate_cache

  def commit
    project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def short_sha
    Commit.truncate_sha(sha)
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
    @manual_actions ||= deployable.try(:other_actions)
  end

  def includes_commit?(commit)
    return false unless commit

    project.repository.ancestor?(commit.id, sha)
  end

  def update_merge_request_metrics!
    return unless environment.update_merge_request_metrics?

    merge_requests = project.merge_requests
                     .joins(:metrics)
                     .where(target_branch: self.ref, merge_request_metrics: { first_deployed_to_production_at: nil })
                     .where("merge_request_metrics.merged_at <= ?", self.created_at)

    if previous_deployment
      merge_requests = merge_requests.where("merge_request_metrics.merged_at >= ?", previous_deployment.created_at)
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
      .update_all(first_deployed_to_production_at: self.created_at)
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

  def stop_action?
    stop_action.present?
  end

  def formatted_deployment_time
    created_at.to_time.in_time_zone.to_s(:medium)
  end

  def has_metrics?
    prometheus_adapter&.can_query?
  end

  def metrics
    return {} unless has_metrics?

    metrics = prometheus_adapter.query(:deployment, self)
    metrics&.merge(deployment_time: created_at.to_i) || {}
  end

  def additional_metrics
    return {} unless has_metrics?

    metrics = prometheus_adapter.query(:additional_metrics_deployment, self)
    metrics&.merge(deployment_time: created_at.to_i) || {}
  end

  private

  def prometheus_adapter
    environment.prometheus_adapter
  end

  def ref_path
    File.join(environment.ref_path, 'deployments', iid.to_s)
  end
end
