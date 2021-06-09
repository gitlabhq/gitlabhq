# frozen_string_literal: true

class Environment < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ReactiveCaching
  include FastDestroyAll::Helpers
  include Presentable

  self.reactive_cache_refresh_interval = 1.minute
  self.reactive_cache_lifetime = 55.seconds
  self.reactive_cache_hard_limit = 10.megabytes
  self.reactive_cache_work_type = :external_dependency

  belongs_to :project, required: true

  use_fast_destroy :all_deployments

  has_many :all_deployments, class_name: 'Deployment'
  has_many :deployments, -> { visible }
  has_many :successful_deployments, -> { success }, class_name: 'Deployment'
  has_many :active_deployments, -> { active }, class_name: 'Deployment'
  has_many :prometheus_alerts, inverse_of: :environment
  has_many :metrics_dashboard_annotations, class_name: 'Metrics::Dashboard::Annotation', inverse_of: :environment
  has_many :self_managed_prometheus_alert_events, inverse_of: :environment
  has_many :alert_management_alerts, class_name: 'AlertManagement::Alert', inverse_of: :environment

  has_one :last_deployment, -> { success.distinct_on_environment }, class_name: 'Deployment', inverse_of: :environment
  has_one :last_deployable, through: :last_deployment, source: 'deployable', source_type: 'CommitStatus'
  has_one :last_pipeline, through: :last_deployable, source: 'pipeline'
  has_one :last_visible_deployment, -> { visible.distinct_on_environment }, inverse_of: :environment, class_name: 'Deployment'
  has_one :last_visible_deployable, through: :last_visible_deployment, source: 'deployable', source_type: 'CommitStatus'
  has_one :last_visible_pipeline, through: :last_visible_deployable, source: 'pipeline'
  has_one :upcoming_deployment, -> { running.distinct_on_environment }, class_name: 'Deployment', inverse_of: :environment
  has_one :latest_opened_most_severe_alert, -> { order_severity_with_open_prometheus_alert }, class_name: 'AlertManagement::Alert', inverse_of: :environment

  before_validation :nullify_external_url
  before_validation :generate_slug, if: ->(env) { env.slug.blank? }

  before_save :set_environment_type
  before_save :ensure_environment_tier
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
            allow_nil: true,
            addressable_url: true

  delegate :stop_action, :manual_actions, to: :last_deployment, allow_nil: true
  delegate :auto_rollback_enabled?, to: :project

  scope :available, -> { with_state(:available) }
  scope :stopped, -> { with_state(:stopped) }

  scope :order_by_last_deployed_at, -> do
    order(Gitlab::Database.nulls_first_order("(#{max_deployment_id_sql})", 'ASC'))
  end
  scope :order_by_last_deployed_at_desc, -> do
    order(Gitlab::Database.nulls_last_order("(#{max_deployment_id_sql})", 'DESC'))
  end
  scope :order_by_name, -> { order('environments.name ASC') }

  scope :in_review_folder, -> { where(environment_type: "review") }
  scope :for_name, -> (name) { where(name: name) }
  scope :preload_cluster, -> { preload(last_deployment: :cluster) }
  scope :auto_stoppable, -> (limit) { available.where('auto_stop_at < ?', Time.zone.now).limit(limit) }

  ##
  # Search environments which have names like the given query.
  # Do not set a large limit unless you've confirmed that it works on gitlab.com scale.
  scope :for_name_like, -> (query, limit: 5) do
    where(arel_table[:name].matches("#{sanitize_sql_like query}%")).limit(limit)
  end

  scope :for_project, -> (project) { where(project_id: project) }
  scope :for_tier, -> (tier) { where(tier: tier).where.not(tier: nil) }
  scope :with_deployment, -> (sha) { where('EXISTS (?)', Deployment.select(1).where('deployments.environment_id = environments.id').where(sha: sha)) }
  scope :unfoldered, -> { where(environment_type: nil) }
  scope :with_rank, -> do
    select('environments.*, rank() OVER (PARTITION BY project_id ORDER BY id DESC)')
  end
  scope :for_id, -> (id) { where(id: id) }

  scope :stopped_review_apps, -> (before, limit) do
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

  state_machine :state, initial: :available do
    event :start do
      transition stopped: :available
    end

    event :stop do
      transition available: :stopped
    end

    state :available
    state :stopped

    after_transition do |environment|
      environment.expire_etag_cache
    end
  end

  def self.for_id_and_slug(id, slug)
    find_by(id: id, slug: slug)
  end

  def self.max_deployment_id_sql
    Deployment.select(Deployment.arel_table[:id].maximum)
    .where(Deployment.arel_table[:environment_id].eq(arel_table[:id]))
    .to_sql
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

  class << self
    ##
    # This method returns stop actions (jobs) for multiple environments within one
    # query. It's useful to avoid N+1 problem.
    #
    # NOTE: The count of environments should be small~medium (e.g. < 5000)
    def stop_actions
      cte = cte_for_deployments_with_stop_action
      ci_builds = Ci::Build.arel_table

      inner_join_stop_actions = ci_builds.join(cte.table).on(
        ci_builds[:project_id].eq(cte.table[:project_id])
          .and(ci_builds[:ref].eq(cte.table[:ref]))
          .and(ci_builds[:name].eq(cte.table[:on_stop]))
      ).join_sources

      pipeline_ids = ci_builds.join(cte.table).on(
        ci_builds[:id].eq(cte.table[:deployable_id])
      ).project(:commit_id)

      Ci::Build.joins(inner_join_stop_actions)
               .with(cte.to_arel)
               .where(ci_builds[:commit_id].in(pipeline_ids))
               .where(status: Ci::HasStatus::BLOCKED_STATUS)
               .preload_project_and_pipeline_project
               .preload(:user, :metadata, :deployment)
    end

    def count_by_state
      environments_count_by_state = group(:state).count

      valid_states.each_with_object({}) do |state, count_hash|
        count_hash[state] = environments_count_by_state[state.to_s] || 0
      end
    end

    private

    def cte_for_deployments_with_stop_action
      Gitlab::SQL::CTE.new(:deployments_with_stop_action,
        Deployment.where(environment_id: select(:id))
          .distinct_on_environment
          .stoppable)
    end
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
      .append(key: 'CI_ENVIRONMENT_TIER', value: tier)
  end

  def recently_updated_on_branch?(ref)
    ref.to_s == last_deployment.try(:ref)
  end

  def nullify_external_url
    self.external_url = nil if self.external_url.blank?
  end

  def set_environment_type
    names = name.split('/')

    self.environment_type = names.many? ? names.first : nil
  end

  def includes_commit?(commit)
    return false unless last_deployment

    last_deployment.includes_commit?(commit)
  end

  def last_deployed_at
    last_deployment.try(:created_at)
  end

  def ref_path
    "refs/#{Repository::REF_ENVIRONMENTS}/#{slug}"
  end

  def formatted_external_url
    return unless external_url

    external_url.gsub(%r{\A.*?://}, '')
  end

  def stop_action_available?
    available? && stop_action.present?
  end

  def cancel_deployment_jobs!
    jobs = active_deployments.with_deployable
    jobs.each do |deployment|
      Gitlab::OptimisticLocking.retry_lock(deployment.deployable, name: 'environment_cancel_deployment_jobs') do |deployable|
        deployable.cancel! if deployable&.cancelable?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, environment_id: id, deployment_id: deployment.id)
    end
  end

  def stop_with_action!(current_user)
    return unless available?

    stop!
    stop_action&.play(current_user)
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
    return unless value
    return unless parsed_result = ChronicDuration.parse(value)

    self.auto_stop_at = parsed_result.seconds.from_now
  end

  def elastic_stack_available?
    !!deployment_platform&.cluster&.elastic_stack_available?
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

  private

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

  # Guessing the tier of the environment if it's not explicitly specified by users.
  # See https://en.wikipedia.org/wiki/Deployment_environment for industry standard deployment environments
  def guess_tier
    case name
    when %r{dev|review|trunk}i then self.class.tiers[:development]
    when %r{test|qc}i then self.class.tiers[:testing]
    when %r{st(a|)g|mod(e|)l|pre|demo}i then self.class.tiers[:staging]
    when %r{pr(o|)d|live}i then self.class.tiers[:production]
    else self.class.tiers[:other]
    end
  end
end

Environment.prepend_mod_with('Environment')
