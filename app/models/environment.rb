# frozen_string_literal: true

class Environment < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ReactiveCaching
  include CacheMarkdownField
  include FastDestroyAll::Helpers
  include Presentable
  include NullifyIfBlank
  include FromUnion

  LONG_STOP = 1.week

  self.reactive_cache_refresh_interval = 1.minute
  self.reactive_cache_lifetime = 55.seconds
  self.reactive_cache_hard_limit = 10.megabytes
  self.reactive_cache_work_type = :external_dependency

  cache_markdown_field :description

  belongs_to :project, optional: false
  belongs_to :merge_request, optional: true
  belongs_to :cluster_agent, class_name: 'Clusters::Agent', optional: true, inverse_of: :environments

  use_fast_destroy :all_deployments
  nullify_if_blank :external_url, :kubernetes_namespace, :flux_resource_path, :description

  has_many :all_deployments, class_name: 'Deployment'
  has_many :deployments, -> { visible }
  has_many :successful_deployments, -> { success }, class_name: 'Deployment'
  has_many :active_deployments, -> { active }, class_name: 'Deployment'
  has_many :alert_management_alerts, class_name: 'AlertManagement::Alert', inverse_of: :environment

  # NOTE: If you preload multiple last deployments of environments, use Preloaders::Environments::DeploymentPreloader.
  has_one :last_deployment, -> { success.ordered }, class_name: 'Deployment', inverse_of: :environment
  has_one :last_finished_deployment, -> { finished.ordered }, class_name: 'Deployment', inverse_of: :environment
  has_one :last_visible_deployment, -> { visible.order(id: :desc) }, inverse_of: :environment, class_name: 'Deployment'
  has_one :upcoming_deployment, -> { upcoming.order(id: :desc) }, class_name: 'Deployment', inverse_of: :environment

  Deployment::FINISHED_STATUSES.each do |status|
    has_one :"last_#{status}_deployment", -> { where(status: status).ordered },
      class_name: 'Deployment', inverse_of: :environment
  end

  Deployment::UPCOMING_STATUSES.each do |status|
    has_one :"last_#{status}_deployment", -> { where(status: status).ordered_as_upcoming },
      class_name: 'Deployment', inverse_of: :environment
  end

  has_one :latest_opened_most_severe_alert, -> { open_order_by_severity }, class_name: 'AlertManagement::Alert', inverse_of: :environment

  before_validation :generate_slug, if: ->(env) { env.slug.blank? }
  before_validation :ensure_environment_tier

  before_save :set_environment_type
  after_save :clear_reactive_cache!

  validates :name,
    presence: true,
    uniqueness: { scope: :project_id },
    length: { maximum: 255 },
    format: { with: Gitlab::Regex.environment_name_regex,
              message: Gitlab::Regex.environment_name_regex_message }

  validates :slug,
    presence: true,
    uniqueness: { scope: :project_id },
    length: { maximum: 24 },
    format: { with: Gitlab::Regex.environment_slug_regex,
              message: Gitlab::Regex.environment_slug_regex_message }

  validates :external_url,
    length: { maximum: 255 },
    allow_nil: true

  validates :description,
    length: { maximum: 10000 },
    allow_nil: true,
    if: :description_changed?

  validates :description_html,
    length: { maximum: 50000 },
    allow_nil: true,
    if: :description_html_changed?

  validates :kubernetes_namespace,
    allow_nil: true,
    length: 1..63,
    format: {
      with: Gitlab::Regex.kubernetes_namespace_regex,
      message: Gitlab::Regex.kubernetes_namespace_regex_message
    },
    absence: { unless: :cluster_agent, message: 'cannot be set without a cluster agent' },
    if: -> { cluster_agent_changed? || kubernetes_namespace_changed? }

  validates :flux_resource_path,
    length: { maximum: 255 },
    allow_nil: true,
    absence: { unless: :kubernetes_namespace, message: 'cannot be set without a kubernetes namespace' },
    if: -> { kubernetes_namespace_changed? || flux_resource_path_changed? }

  validates :tier, presence: true

  validate :safe_external_url
  validate :merge_request_not_changed

  delegate :manual_actions, to: :last_deployment, allow_nil: true
  delegate :auto_rollback_enabled?, to: :project

  scope :available, -> { with_state(:available) }
  scope :active, -> { with_state(:available, :stopping) }
  scope :stopped, -> { with_state(:stopped) }

  scope :order_by_last_deployed_at, -> do
    order(Arel::Nodes::Grouping.new(max_deployment_id_query).asc.nulls_first)
  end
  scope :order_by_last_deployed_at_desc, -> do
    order(Arel::Nodes::Grouping.new(max_deployment_id_query).desc.nulls_last)
  end
  scope :order_by_name, -> { order('environments.name ASC') }

  scope :in_review_folder, -> { where(environment_type: "review") }
  scope :for_name, ->(name) { where(name: name) }
  scope :preload_project, -> { preload(:project) }
  scope :auto_stoppable, ->(limit) { available.where('auto_stop_at < ?', Time.zone.now).limit(limit) }
  scope :auto_deletable, ->(limit) { stopped.where('auto_delete_at < ?', Time.zone.now).limit(limit) }
  scope :long_stopping,  -> { with_state(:stopping).where('updated_at < ?', LONG_STOP.ago) }

  scope :deployed_and_updated_before, ->(project_id, before) do
    # this query joins deployments and filters out any environment that has recent deployments
    joins = %(
    LEFT JOIN "deployments" on "deployments".environment_id = "environments".id
        AND "deployments".project_id = #{project_id}
        AND "deployments".updated_at >= #{connection.quote(before)}
    )
    Environment.joins(joins)
               .where(project_id: project_id, updated_at: ...before)
               .group('id', 'deployments.id')
               .having('deployments.id IS NULL')
  end
  scope :without_protected, ->(project) {} # no-op when not in EE mode

  scope :without_names, ->(names) do
    where.not(name: names)
  end
  scope :without_tiers, ->(tiers) do
    where.not(tier: tiers)
  end

  ##
  # Search environments which have names like the given query.
  # Do not set a large limit unless you've confirmed that it works on gitlab.com scale.
  scope :for_name_like, ->(query, limit: 5) do
    top_level = 'LOWER(environments.name) LIKE LOWER(?) || \'%\''

    where(top_level, sanitize_sql_like(query)).limit(limit)
  end

  scope :for_name_like_within_folder, ->(query, limit: 5) do
    within_folder_name = "LOWER(ltrim(ltrim(environments.name, environments.environment_type), '/'))"

    where("#{within_folder_name} LIKE (LOWER(?) || '%')", sanitize_sql_like(query)).limit(limit)
  end

  scope :for_project, ->(project) { where(project_id: project) }
  scope :for_tier, ->(tier) { where(tier: tier).where.not(tier: nil) }
  scope :for_type, ->(type) { where(environment_type: type) }
  scope :unfoldered, -> { where(environment_type: nil) }
  scope :with_rank, -> do
    select('environments.*, rank() OVER (PARTITION BY project_id ORDER BY id DESC)')
  end

  scope :with_deployment, ->(sha, status: nil) do
    deployments = Deployment.select(1).where('deployments.environment_id = environments.id').where(sha: sha)
    deployments = deployments.where(status: status) if status

    where('EXISTS (?)', deployments)
  end

  scope :stopped_review_apps, ->(before, limit) do
    stopped
      .in_review_folder
      .where("created_at < ?", before)
      .order("created_at ASC")
      .limit(limit)
  end

  scope :scheduled_for_deletion, -> do
    where.not(auto_delete_at: nil)
  end

  scope :not_scheduled_for_deletion, -> do
    where(auto_delete_at: nil)
  end

  enum tier: {
    production: 0,
    staging: 1,
    testing: 2,
    development: 3,
    other: 4
  }

  enum auto_stop_setting: {
    always: 0,
    with_action: 1
  }, _prefix: true

  state_machine :state, initial: :available do
    event :start do
      transition %i[stopped stopping] => :available
    end

    event :stop do
      transition available: :stopping, if: :wait_for_stop?
      transition available: :stopped, unless: :wait_for_stop?
    end

    event :stop_complete do
      transition %i[available stopping] => :stopped
    end

    event :recover_stuck_stopping do
      transition stopping: :available
    end

    state :available
    state :stopping
    state :stopped

    before_transition any => :stopped do |environment|
      environment.auto_stop_at = nil
    end

    after_transition do |environment|
      environment.expire_etag_cache
    end
  end

  def self.for_id_and_slug(id, slug)
    find_by(id: id, slug: slug)
  end

  def self.max_deployment_id_query
    Arel.sql(
      Deployment.select(Deployment.arel_table[:id].maximum)
      .where(Deployment.arel_table[:environment_id].eq(arel_table[:id])).to_sql
    )
  end

  def self.pluck_names
    pluck(:name)
  end

  def self.pluck_unique_names
    pluck('DISTINCT(environments.name)')
  end

  def self.find_or_create_by_name(name)
    find_or_create_by(name: name)
  end

  def self.valid_states
    self.state_machine.states.map(&:name)
  end

  def self.schedule_to_delete(at_time = 1.week.from_now)
    update_all(auto_delete_at: at_time)
  end

  def self.nested
    group('COALESCE(environment_type, id::text)', 'COALESCE(environment_type, name)')
      .select('COALESCE(environment_type, id::text), COALESCE(environment_type, name) AS name', 'COUNT(*) AS size', 'MAX(id) AS last_id')
      .order('name ASC')
  end

  class << self
    def count_by_state
      environments_count_by_state = group(:state).count

      valid_states.index_with do |state|
        environments_count_by_state[state.to_s] || 0
      end
    end
  end

  def last_deployable
    last_deployment&.deployable
  end

  def last_finished_deployable
    last_finished_deployment&.deployable
  end

  def last_finished_pipeline
    last_finished_deployable&.pipeline
  end

  def latest_finished_jobs
    last_finished_pipeline&.latest_finished_jobs
  end

  def last_visible_deployable
    last_visible_deployment&.deployable
  end

  def last_visible_pipeline
    last_visible_deployable&.pipeline
  end

  def clear_prometheus_reactive_cache!(query_name)
    cluster_prometheus_adapter&.clear_prometheus_reactive_cache!(query_name, self)
  end

  def cluster_prometheus_adapter
    @cluster_prometheus_adapter ||= ::Gitlab::Prometheus::Adapter.new(project, deployment_platform&.cluster).cluster_prometheus_adapter
  end

  def predefined_variables
    Gitlab::Ci::Variables::Collection.new
      .append(key: 'CI_ENVIRONMENT_NAME', value: name)
      .append(key: 'CI_ENVIRONMENT_SLUG', value: slug)
  end

  def recently_updated_on_branch?(ref)
    ref.to_s == last_deployment.try(:ref)
  end

  def set_environment_type
    names = name.split('/')

    self.environment_type = names.many? ? names.first : nil
  end

  def includes_commit?(sha)
    return false unless last_deployment

    last_deployment.includes_commit?(sha)
  end

  def last_deployed_at
    last_deployment.try(:created_at)
  end

  def long_stopping?
    stopping? && self.updated_at < LONG_STOP.ago
  end

  def ref_path
    "refs/#{Repository::REF_ENVIRONMENTS}/#{slug}"
  end

  def formatted_external_url
    return unless external_url

    external_url.gsub(%r{\A.*?://}, '')
  end

  def stop_actions_available?
    available? && stop_actions.present?
  end

  def cancel_deployment_jobs!
    active_deployments.jobs.each do |job|
      Gitlab::OptimisticLocking.retry_lock(job, name: 'environment_cancel_deployment_jobs') do |job|
        job.cancel! if job&.cancelable?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, environment_id: id, deployment_id: deployment.id)
    end
  end

  def wait_for_stop?
    stop_actions.present?
  end

  # TODO: move this method and dependencies into Environments::StopService
  def stop_with_actions!
    return unless available?

    if stop_actions.any? || auto_stop_setting_always?
      stop!
    end

    # The current_user stopping the environment may not be the same actor that we use
    # to run the stop action jobs. We need to ensure that if any of the actors require
    # composite identity we link it before hand.
    # This design assumes that all `stop_actions` have the same user.
    link_identity = ::Gitlab::Auth::Identity.currently_linked.blank?

    stop_actions.filter_map do |stop_action|
      run_stop_action!(stop_action, link_identity: link_identity)
    end
  end

  def stop_actions
    last_finished_deployment_group.map(&:stop_action).compact
  end
  strong_memoize_attr :stop_actions

  def last_finished_deployment_group
    Deployment.last_finished_deployment_group_for_environment(self)
  end

  def reset_auto_stop
    update_column(:auto_stop_at, nil)
  end

  def actions_for(environment)
    return [] unless manual_actions

    manual_actions.select do |action|
      action.expanded_environment_name == environment
    end
  end

  def has_terminals?
    available? && deployment_platform.present? && last_deployment.present?
  end

  def terminals
    with_reactive_cache do |data|
      deployment_platform.terminals(self, data)
    end
  end

  def calculate_reactive_cache
    return unless has_terminals? && !project.pending_delete?

    deployment_platform.calculate_reactive_cache_for(self)
  end

  def deployment_namespace
    strong_memoize(:kubernetes_namespace) do
      deployment_platform.cluster.kubernetes_namespace_for(self) if deployment_platform
    end
  end

  def has_metrics?
    available? && (prometheus_adapter&.configured? || has_sample_metrics?)
  end

  def has_sample_metrics?
    !!ENV['USE_SAMPLE_METRICS']
  end

  def has_opened_alert?
    latest_opened_most_severe_alert.present?
  end

  def has_running_deployments?
    all_deployments.running.exists?
  end

  def metrics
    prometheus_adapter.query(:environment, self) if has_metrics_and_can_query?
  end

  def additional_metrics(*args)
    return unless has_metrics_and_can_query?

    prometheus_adapter.query(:additional_metrics_environment, self, *args.map(&:to_f))
  end

  def prometheus_adapter
    @prometheus_adapter ||= Gitlab::Prometheus::Adapter.new(project, deployment_platform&.cluster).prometheus_adapter
  end

  def slug
    super.presence || generate_slug
  end

  def external_url_for(path, commit_sha)
    return unless self.external_url

    public_path = project.public_path_for_source_path(path, commit_sha)
    return unless public_path

    [external_url.delete_suffix('/'), public_path.delete_prefix('/')].join('/')
  end

  def expire_etag_cache
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(etag_cache_key)
    end
  end

  def etag_cache_key
    Gitlab::Routing.url_helpers.project_environments_path(
      project,
      format: :json)
  end

  def folder_name
    self.environment_type || self.name
  end

  def name_without_type
    @name_without_type ||= name.delete_prefix("#{environment_type}/")
  end

  def deployment_platform
    strong_memoize(:deployment_platform) do
      project.deployment_platform(environment: self.name)
    end
  end

  def knative_services_finder
    if last_deployment&.cluster
      Clusters::KnativeServicesFinder.new(last_deployment.cluster, self)
    end
  end

  def auto_stop_in
    auto_stop_at - Time.current if auto_stop_at
  end

  def auto_stop_in=(value)
    if value.nil?
      # Handles edge case when auto_stop_at is already set and the new value is nil.
      # Possible by setting `auto_stop_in: null` in the CI configuration yml.
      self.auto_stop_at = nil

      return
    end

    parser = ::Gitlab::Ci::Build::DurationParser.new(value)

    self.auto_stop_at = parser.seconds_from_now
  rescue ChronicDuration::DurationParseError => ex
    Gitlab::ErrorTracking.track_exception(ex, project_id: self.project_id, environment_id: self.id)
    raise ex
  end

  def rollout_status
    return unless rollout_status_available?

    result = rollout_status_with_reactive_cache

    result || ::Gitlab::Kubernetes::RolloutStatus.loading
  end

  def ingresses
    return unless rollout_status_available?

    deployment_platform.ingresses(deployment_namespace)
  end

  def patch_ingress(ingress, data)
    return unless rollout_status_available?

    deployment_platform.patch_ingress(deployment_namespace, ingress, data)
  end

  def clear_all_caches
    expire_etag_cache
    clear_reactive_cache!
  end

  def should_link_to_merge_requests?
    unfoldered? || production? || staging?
  end

  def unfoldered?
    environment_type.nil?
  end

  def deploy_freezes
    Gitlab::SafeRequestStore.fetch("project:#{project_id}:freeze_periods_for_environments") do
      project.freeze_periods
    end
  end

  private

  def run_stop_action!(job, link_identity:)
    ::Gitlab::Auth::Identity.link_from_job(job) if link_identity

    job.play(job.user)
  rescue StateMachines::InvalidTransition
    # Ci::PlayBuildService rescues an error of StateMachines::InvalidTransition and fall back to retry.
    # However, Ci::PlayBridgeService doesn't rescue it, so we're ignoring the error if it's not playable.
    # We should fix this inconsistency in https://gitlab.com/gitlab-org/gitlab/-/issues/420855.
  end

  # We deliberately avoid using AddressableUrlValidator to allow users to update their environments even if they have
  # misconfigured `environment:url` keyword. The external URL is presented as a clickable link on UI and not consumed
  # in GitLab internally, thus we sanitize the URL before the persistence to make sure the rendered link is XSS safe.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/337417
  def safe_external_url
    return unless self.external_url.present?

    new_external_url = Addressable::URI.parse(self.external_url)

    if Gitlab::Utils::SanitizeNodeLink::UNSAFE_PROTOCOLS.include?(new_external_url.normalized_scheme)
      errors.add(:external_url, "#{new_external_url.normalized_scheme} scheme is not allowed")
    end
  rescue Addressable::URI::InvalidURIError
    errors.add(:external_url, 'URI is invalid')
  end

  def rollout_status_available?
    has_terminals?
  end

  def rollout_status_with_reactive_cache
    with_reactive_cache do |data|
      deployment_platform.rollout_status(self, data)
    end
  end

  def has_metrics_and_can_query?
    has_metrics? && prometheus_adapter.can_query?
  end

  def generate_slug
    self.slug = Gitlab::Slug::Environment.new(name).generate
  end

  def ensure_environment_tier
    self.tier ||= guess_tier
  end

  def merge_request_not_changed
    if merge_request_id_changed? && persisted?
      errors.add(:merge_request, 'merge_request cannot be changed')
    end
  end

  # Guessing the tier of the environment if it's not explicitly specified by users.
  # See https://en.wikipedia.org/wiki/Deployment_environment for industry standard deployment environments
  def guess_tier
    case name
    when /(dev|review|trunk)/i
      self.class.tiers[:development]
    when /(test|tst|int|ac(ce|)pt|qa|qc|control|quality)/i
      self.class.tiers[:testing]
    when /(st(a|)g|mod(e|)l|pre|demo|non)/i
      self.class.tiers[:staging]
    when /(pr(o|)d|live)/i
      self.class.tiers[:production]
    else
      self.class.tiers[:other]
    end
  end
end

Environment.prepend_mod_with('Environment')
