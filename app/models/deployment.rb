# frozen_string_literal: true

class Deployment < ApplicationRecord
  include AtomicInternalId
  include IidRoutes
  include AfterCommitQueue
  include UpdatedAtFilterable
  include Importable
  include Gitlab::Utils::StrongMemoize
  include FastDestroyAll
  include EachBatch

  StatusUpdateError = Class.new(StandardError)
  StatusSyncError = Class.new(StandardError)

  ARCHIVABLE_OFFSET = 50_000

  belongs_to :project, optional: false
  belongs_to :environment, optional: false
  belongs_to :user
  belongs_to :deployable, polymorphic: true, optional: true, inverse_of: :deployment # rubocop:disable Cop/PolymorphicAssociations -- It's necessary

  has_many :deployment_merge_requests
  has_many :merge_requests, through: :deployment_merge_requests

  has_one :deployment_cluster

  has_internal_id :iid, scope: :project, track_if: -> { !importing? }

  validates :sha, presence: true
  validates :ref, presence: true
  validate :valid_sha, on: :create
  validate :valid_ref, on: :create

  delegate :name, to: :environment, prefix: true
  delegate :kubernetes_namespace, to: :deployment_cluster, allow_nil: true
  delegate :cluster, to: :deployment_cluster, allow_nil: true

  scope :for_iid, ->(project, iid) { where(project: project, iid: iid) }
  scope :for_environment, ->(environment) { where(environment_id: environment) }
  scope :for_environment_name, ->(project, name) do
    where('deployments.environment_id = (?)',
      Environment.select(:id).where(project: project, name: name).limit(1))
  end

  scope :for_status, ->(status) { where(status: status) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_projects, ->(projects) { where(project: projects) }

  scope :visible, -> { where(status: VISIBLE_STATUSES) }
  scope :finished, -> { where(status: FINISHED_STATUSES) }
  scope :stoppable, -> { where.not(on_stop: nil).where.not(deployable_id: nil).success }
  scope :active, -> { where(status: %i[created running]) }
  scope :upcoming, -> { where(status: %i[blocked running]) }
  scope :older_than, ->(deployment) { where('deployments.id < ?', deployment.id) }
  scope :with_api_entity_associations, -> do
    preload({ deployable: { runner: [], tags: [], user: [], job_artifacts_archive: [] } })
  end
  scope :with_environment_page_associations, -> do
    preload(project: [], environment: [], deployable: [:user, :metadata, :project, { pipeline: [:manual_actions] }])
  end

  scope :finished_after, ->(date) { where('finished_at >= ?', date) }
  scope :finished_before, ->(date) { where('finished_at < ?', date) }

  scope :ordered, -> { order(finished_at: :desc) }
  scope :ordered_as_upcoming, -> { order(id: :desc) }

  VISIBLE_STATUSES = %i[running success failed canceled blocked].freeze
  FINISHED_STATUSES = %i[success failed canceled].freeze
  UPCOMING_STATUSES = %i[created blocked running].freeze

  state_machine :status, initial: :created do
    event :run do
      transition [:created, :blocked] => :running
    end

    event :block do
      transition created: :blocked
    end

    # This transition is possible when we have manual jobs.
    event :create do
      transition skipped: :created
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

    event :skip do
      transition any - [:skipped] => :skipped
    end

    before_transition any => FINISHED_STATUSES do |deployment|
      deployment.finished_at = Time.current
    end

    after_transition any => :running do |deployment, transition|
      deployment.run_after_commit do
        perform_params = { deployment_id: id, status: transition.to, status_changed_at: Time.current }

        serialize_params_for_sidekiq!(perform_params)

        Deployments::HooksWorker.perform_async(perform_params)
      end
    end

    after_transition any => :success do |deployment|
      deployment.run_after_commit do
        Deployments::UpdateEnvironmentWorker.perform_async(id)
        Deployments::LinkMergeRequestWorker.perform_async(id)
        Deployments::ArchiveInProjectWorker.perform_async(deployment.project_id)
      end
    end

    after_transition any => FINISHED_STATUSES do |deployment, transition|
      deployment.run_after_commit do
        perform_params = { deployment_id: id, status: transition.to, status_changed_at: Time.current }

        serialize_params_for_sidekiq!(perform_params)

        Deployments::HooksWorker.perform_async(perform_params)
      end
    end

    after_transition any => any - [:skipped] do |deployment, transition|
      next if transition.loopback?

      deployment.run_after_commit do
        next unless deployment.project.jira_subscription_exists?

        ::JiraConnect::SyncDeploymentsWorker.perform_async(id)
      end
    end
  end

  after_create unless: :importing? do |deployment|
    run_after_commit do
      next unless deployment.project.jira_subscription_exists?

      ::JiraConnect::SyncDeploymentsWorker.perform_async(deployment.id)
    end
  end

  enum status: {
    created: 0,
    running: 1,
    success: 2,
    failed: 3,
    canceled: 4,
    skipped: 5,
    blocked: 6
  }

  def self.archivables_in(project, limit:)
    start_iid = project.deployments.order(iid: :desc).limit(1)
      .select("(iid - #{ARCHIVABLE_OFFSET}) AS start_iid")

    project.deployments.preload(:environment).where('iid <= (?)', start_iid)
      .where(archived: false).limit(limit)
  end

  def self.last_for_environment(environment)
    ids = for_environment(environment).select('MAX(id) AS id').group(:environment_id).map(&:id)
    find(ids)
  end

  # This method returns the *finished deployments* of the *last finished pipeline* for a given environment
  # e.g., a finished pipeline contains
  #   - deploy job A (environment: production, status: success)
  #   - deploy job B (environment: production, status: failed)
  #   - deploy job C (environment: production, status: canceled)
  # In the above case, `last_finished_deployment_group_for_environment` returns all deployments
  def self.last_finished_deployment_group_for_environment(env)
    return none unless env.latest_finished_jobs.present?

    # this batch loads a collection of deployments associated to `latest_finished_jobs` per `environment`
    BatchLoader.for(env).batch(key: :latest_finished_jobs, default_value: none) do |environments, loader|
      job_ids = []
      environments_hash = {}

      # Preloading the environment's `latest_finished_jobs` avoids N+1 queries.
      environments.each do |environment|
        environments_hash[environment.id] = environment

        job_ids << environment.latest_finished_jobs.map(&:id)
      end

      Deployment
        .where(deployable_type: 'CommitStatus', deployable_id: job_ids.flatten)
        .preload(last_deployment_group_associations)
        .group_by(&:environment_id)
        .each do |env_id, deployment_group|
          loader.call(environments_hash[env_id], deployment_group)
        end
    end
  end

  def self.find_successful_deployment!(iid)
    success.find_by!(iid: iid)
  end

  # It should be used with caution especially on chaining.
  # Fetching any unbounded or large intermediate dataset could lead to loading too many IDs into memory.
  # See: https://docs.gitlab.com/ee/development/database/multiple_databases.html#use-disable_joins-for-has_one-or-has_many-through-relations
  # For safety we default limit to fetch not more than 1000 records.
  def self.jobs(limit = 1000)
    deployable_ids = where.not(deployable_id: nil).limit(limit).pluck(:deployable_id)

    Ci::Processable.where(id: deployable_ids)
  end

  def job
    deployable if deployable.is_a?(::Ci::Processable)
  end

  class << self
    ##
    # FastDestroyAll concerns
    def begin_fast_destroy
      preload(:project, :environment).find_each.map do |deployment|
        [deployment.project, deployment.ref_path]
      end
    end

    ##
    # FastDestroyAll concerns
    def finalize_fast_destroy(params)
      by_project = params.group_by(&:shift)

      by_project.each do |project, ref_paths|
        project.repository.delete_refs(*ref_paths.flatten)
      rescue Gitlab::Git::Repository::NoRepository
        next
      end
    end

    def latest_for_sha(sha)
      where(sha: sha).order(id: :desc).take
    end
  end

  def commit
    @commit ||= project.commit(sha)
  end

  def commit_title
    commit.try(:title)
  end

  def short_sha
    Commit.truncate_sha(sha)
  end

  def execute_hooks(status, status_changed_at)
    deployment_data = Gitlab::DataBuilder::Deployment.build(self, status, status_changed_at)
    project.execute_hooks(deployment_data, :deployment_hooks)
    project.execute_integrations(deployment_data, :deployment_hooks)
  end

  def last?
    self == environment.last_deployment
  end

  def create_ref
    project.repository.create_ref(sha, ref_path)
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

  def playable_job
    deployable.try(:playable?) ? deployable : nil
  end
  strong_memoize_attr :playable_job

  def includes_commit?(ancestor_sha)
    return false unless sha

    project.repository.ancestor?(ancestor_sha, sha)
  end

  def older_than_last_successful_deployment?
    last_deployment_id = environment&.last_deployment&.id

    return false unless last_deployment_id.present?
    return false if id == last_deployment_id
    return false if sha == environment.last_deployment&.sha

    id < last_deployment_id
  end

  def update_merge_request_metrics!
    return unless environment.production? && success?

    merge_requests = project.merge_requests
                     .joins(:metrics)
                     .where(target_branch: ref, merge_request_metrics: { first_deployed_to_production_at: nil })
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
      self.class.for_environment(environment_id)
        .success
        .where('id < ?', id)
        .order(id: :desc)
        .take
  end

  def stop_action
    return unless on_stop.present?
    return unless manual_actions

    @stop_action ||= manual_actions.find { |action| action.name == on_stop }
  end

  def deployed_at
    return unless success?

    finished_at
  end

  def formatted_deployment_time
    deployed_at&.to_time&.in_time_zone&.to_fs(:medium)
  end

  def deployed_by
    # We use deployable's user if available because Ci::PlayBuildService and Ci::PlayBridgeService
    # do not update the deployment's user, just the one for the deployable.
    # TODO: use deployment's user once https://gitlab.com/gitlab-org/gitlab-foss/issues/66442
    # is completed.
    deployable&.user || user
  end

  def triggered_by?(user)
    deployed_by == user
  end

  def link_merge_requests(relation)
    # NOTE: relation.select will perform column deduplication,
    # when id == environment_id it will outputs 2 columns instead of 3
    # i.e.:
    # MergeRequest.select(1, 2).to_sql #=> SELECT 1, 2 FROM "merge_requests"
    # MergeRequest.select(1, 1).to_sql #=> SELECT 1 FROM "merge_requests"
    select = relation.select(
      'merge_requests.id',
      "#{id} as deployment_id",
      "#{environment_id} as environment_id"
    ).to_sql

    # We don't use `ApplicationRecord.legacy_bulk_insert` here so that we don't need to
    # first pluck lots of IDs into memory.
    #
    # We also ignore any duplicates so this method can be called multiple times
    # for the same deployment, only inserting any missing merge requests.
    DeploymentMergeRequest.connection.execute(<<~SQL)
      INSERT INTO #{DeploymentMergeRequest.table_name}
      (merge_request_id, deployment_id, environment_id)
      #{select}
      ON CONFLICT DO NOTHING
    SQL
  end

  # Changes the status of a deployment and triggers the corresponding state
  # machine events.
  def update_status(status)
    update_status!(status)
  rescue StandardError => e
    error = StatusUpdateError.new(e.message)
    error.set_backtrace(caller)
    Gitlab::ErrorTracking.track_exception(error, deployment_id: id)
    false
  end

  def sync_status_with(job)
    job_status = job.status
    job_status = 'blocked' if job_status == 'manual'

    return false unless ::Deployment.statuses.include?(job_status)
    return false if job_status == status

    update_status!(job_status)
  rescue StandardError => e
    error = StatusSyncError.new(e.message)
    error.set_backtrace(caller)
    Gitlab::ErrorTracking.track_exception(error, deployment_id: id, job_id: job.id)
    false
  end

  def valid_sha
    return if project&.commit(sha)

    errors.add(:sha, _('The commit does not exist'))
  end

  def valid_ref
    return if project&.commit(ref)

    errors.add(:ref, _('The branch or tag does not exist'))
  end

  def ref_path
    File.join(environment.ref_path, 'deployments', iid.to_s)
  end

  def equal_to?(params)
    ref == params[:ref] &&
      tag == params[:tag] &&
      sha == params[:sha] &&
      status == params[:status]
  end

  def tier_in_yaml
    return unless deployable

    deployable.environment_tier_from_options
  end

  # default tag limit is 100, 0 means no limit
  # when refs_by_oid is passed an SHA, returns refs for that commit
  def tags(limit: 100)
    strong_memoize_with(:tag, limit) do
      project.repository.refs_by_oid(oid: sha, limit: limit, ref_patterns: [Gitlab::Git::TAG_REF_PREFIX])
    end
  end

  private

  def update_status!(status)
    case status
    when 'running'
      run!
    when 'success'
      succeed!
    when 'failed'
      drop!
    when 'canceling'
      # no-op
    when 'canceled'
      cancel!
    when 'skipped'
      skip!
    when 'blocked'
      block!
    when 'created'
      create!
    else
      raise ArgumentError, "The status #{status.inspect} is invalid"
    end
  end

  def serialize_params_for_sidekiq!(perform_params)
    perform_params[:status_changed_at] = perform_params[:status_changed_at].to_s
    perform_params.stringify_keys!
  end

  def self.last_deployment_group_associations
    {
      deployable: {
        pipeline: {
          manual_actions: []
        }
      }
    }
  end

  private_class_method :last_deployment_group_associations
end

Deployment.prepend_mod_with('Deployment')
