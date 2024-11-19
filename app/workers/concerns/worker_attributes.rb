# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern
  include Gitlab::ClassAttributes

  # Resource boundaries that workers can declare through the
  # `resource_boundary` attribute
  VALID_RESOURCE_BOUNDARIES = [:memory, :cpu, :unknown].freeze

  # Urgencies that workers can declare through the `urgencies` attribute
  VALID_URGENCIES = [:high, :low, :throttled].freeze

  # Ordered in increasing restrictiveness
  VALID_DATA_CONSISTENCIES = [:delayed, :sticky, :always].freeze
  LOAD_BALANCED_DATA_CONSISTENCIES = [:delayed, :sticky].freeze

  DEFAULT_DATA_CONSISTENCY = :always
  DEFAULT_DATA_CONSISTENCY_PER_DB = Gitlab::Database::LoadBalancing.each_load_balancer.to_h do |lb|
    [lb.name, DEFAULT_DATA_CONSISTENCY]
  end.freeze

  NAMESPACE_WEIGHTS = {
    auto_devops: 2,
    auto_merge: 3,
    chaos: 2,
    deployment: 3,
    mail_scheduler: 2,
    notifications: 2,
    pipeline_cache: 3,
    pipeline_creation: 4,
    pipeline_default: 3,
    pipeline_hooks: 2,
    pipeline_processing: 5,

    # EE-specific
    epics: 2,
    incident_management: 2,
    security_scans: 2
  }.stringify_keys.freeze

  DEFAULT_DEFER_DELAY = 5.seconds

  class_methods do
    def feature_category(value, *extras)
      set_class_attribute(:feature_category, value)
    end

    def prefer_calling_context_feature_category(preference = false)
      set_class_attribute(:prefer_calling_context_feature_category, preference)
    end

    # Special case: if a worker is not owned, get the feature category
    # (if present) from the calling context.
    def get_feature_category
      feature_category = get_class_attribute(:feature_category)
      calling_context_feature_category_preferred = !!get_class_attribute(:prefer_calling_context_feature_category)

      return feature_category unless feature_category == :not_owned || calling_context_feature_category_preferred

      Gitlab::ApplicationContext.current_context_attribute('meta.feature_category') || feature_category
    end

    def feature_category_not_owned?
      get_feature_category == :not_owned
    end

    # This should be set to :high for jobs that need to be run
    # immediately, or, if they are delayed, risk creating
    # inconsistencies in the application that could being perceived by
    # the user as incorrect behavior (ie, a bug)
    #
    # See
    # doc/development/sidekiq_style_guide.md#urgency
    # for details
    def urgency(urgency)
      raise "Invalid urgency: #{urgency}" unless VALID_URGENCIES.include?(urgency)

      set_class_attribute(:urgency, urgency)
    end

    def get_urgency
      get_class_attribute(:urgency) || :low
    end

    # Allows configuring worker's data_consistency.
    #
    #  Worker can utilize Sidekiq readonly database replicas capabilities by setting data_consistency attribute.
    #  Workers with data_consistency set to :delayed or :sticky, calling #perform_async
    #  will be delayed in order to give replication process enough time to complete.
    #
    #  - *default* - The default data_consistency value. Valid values are:
    #    - 'always' - The job is required to use the primary database (default).
    #    - 'sticky' - The job uses a replica as long as possible. It switches to primary either on write or long replication lag.
    #    - 'delayed' - The job would switch to primary only on write. It would use replica always.
    #      If there's a long replication lag the job will be delayed, and only if the replica is not up to date on the next retry,
    #      it will switch to the primary.
    #  - *overrides* - allows you to override data consistency for specific database connections. Only used in multiple
    #    database mode. Valid for values in `Gitlab::Database.database_base_models.keys`
    #  - *feature_flag* - allows you to toggle a job's `data_consistency, which permits you to safely toggle load balancing capabilities for a specific job.
    #    If disabled, job will default to `:always`, which means that the job will always use the primary.
    def data_consistency(default, overrides: nil, feature_flag: nil)
      validate_data_consistency(default, overrides)
      raise ArgumentError, 'Data consistency is already set' if class_attributes[:data_consistency]

      set_class_attribute(:data_consistency_feature_flag, feature_flag) if feature_flag
      set_class_attribute(:data_consistency, default)

      # only override data consistency when using multiple databases
      overrides = nil unless Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES
      set_class_attribute(:data_consistency_per_database, compute_data_consistency_per_database(default, overrides))
    end

    def validate_data_consistency(data_consistency, db_specific)
      valid_default = VALID_DATA_CONSISTENCIES.include?(data_consistency)
      raise ArgumentError, "Invalid data consistency: #{data_consistency}" unless valid_default

      return unless db_specific

      valid_db_specific_hash = db_specific.values.all? { |dc| VALID_DATA_CONSISTENCIES.include?(dc) }
      raise ArgumentError, "Invalid data consistency: #{db_specific}" unless valid_db_specific_hash
    end

    # If data_consistency is not set to :always, worker will try to utilize load balancing capabilities and use the replica
    def utilizes_load_balancing_capabilities?
      get_data_consistency_per_database.values.any? { |v| LOAD_BALANCED_DATA_CONSISTENCIES.include?(v) }
    end

    def get_least_restrictive_data_consistency
      consistencies = get_data_consistency_per_database.values
      VALID_DATA_CONSISTENCIES.find { |dc| consistencies.include?(dc) } || DEFAULT_DATA_CONSISTENCY # rubocop:disable Gitlab/NoFindInWorkers -- not ActiveRecordFind
    end

    def get_data_consistency_per_database
      dc_hash = get_class_attribute(:data_consistency_per_database) if get_data_consistency_feature_flag_enabled?
      dc_hash || DEFAULT_DATA_CONSISTENCY_PER_DB
    end

    def compute_data_consistency_per_database(default, overrides)
      hash = overrides || {}

      Gitlab::Database::LoadBalancing.each_load_balancer do |lb|
        hash[lb.name] ||= default || DEFAULT_DATA_CONSISTENCY
      end

      hash
    end

    def get_data_consistency_feature_flag_enabled?
      return true unless get_class_attribute(:data_consistency_feature_flag)

      Feature.enabled?(get_class_attribute(:data_consistency_feature_flag), Feature.current_request, type: :worker)
    end

    # Set this attribute on a job when it will call to services outside of the
    # application, such as 3rd party applications, other k8s clusters etc See
    # doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies for
    # details
    def worker_has_external_dependencies!
      set_class_attribute(:external_dependencies, true)
    end

    # Returns true if the worker has external dependencies.
    # See doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies
    # for details
    def worker_has_external_dependencies?
      !!get_class_attribute(:external_dependencies)
    end

    def worker_resource_boundary(boundary)
      raise "Invalid boundary" unless VALID_RESOURCE_BOUNDARIES.include? boundary

      set_class_attribute(:resource_boundary, boundary)
    end

    def get_worker_resource_boundary
      get_class_attribute(:resource_boundary) || :unknown
    end

    def idempotent!
      set_class_attribute(:idempotent, true)
    end

    def idempotent?
      !!get_class_attribute(:idempotent)
    end

    def weight(value)
      set_class_attribute(:weight, value)
    end

    def pause_control(value)
      ::Gitlab::SidekiqMiddleware::PauseControl::WorkersMap.set_strategy_for(strategy: value, worker: self)
    end

    def get_pause_control
      ::Gitlab::SidekiqMiddleware::PauseControl::WorkersMap.strategy_for(worker: self)
    end

    def concurrency_limit(max_jobs)
      ::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.set_limit_for(
        worker: self,
        max_jobs: max_jobs
      )
    end

    def get_weight
      get_class_attribute(:weight) ||
        NAMESPACE_WEIGHTS[queue_namespace] ||
        1
    end

    def tags(*values)
      set_class_attribute(:tags, values)
    end

    def get_tags
      Array(get_class_attribute(:tags))
    end

    def deduplicate(strategy, options = {})
      set_class_attribute(:deduplication_strategy, strategy)
      set_class_attribute(:deduplication_options, options)
    end

    def get_deduplicate_strategy
      get_class_attribute(:deduplication_strategy) ||
        Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob::DEFAULT_STRATEGY
    end

    def get_deduplication_options
      get_class_attribute(:deduplication_options) || {}
    end

    def deduplication_enabled?
      return true unless get_deduplication_options[:feature_flag]

      Feature.enabled?(get_deduplication_options[:feature_flag], type: :worker)
    end

    def big_payload!
      set_class_attribute(:big_payload, true)
    end

    def big_payload?
      !!get_class_attribute(:big_payload)
    end

    def defer_on_database_health_signal(gitlab_schema, tables = [], delay_by = DEFAULT_DEFER_DELAY, &block)
      set_class_attribute(
        :database_health_check_attrs,
        { gitlab_schema: gitlab_schema, tables: tables, delay_by: delay_by, block: block }
      )
    end

    def defer_on_database_health_signal?
      database_health_check_attrs.present?
    end

    def database_health_check_attrs
      get_class_attribute(:database_health_check_attrs)
    end
  end
end
