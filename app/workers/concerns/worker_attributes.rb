# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern
  include Gitlab::ClassAttributes

  # Resource boundaries that workers can declare through the
  # `resource_boundary` attribute
  VALID_RESOURCE_BOUNDARIES = [:memory, :cpu, :unknown].freeze

  # Urgencies that workers can declare through the `urgencies` attribute
  VALID_URGENCIES = [:high, :low, :throttled].freeze

  VALID_DATA_CONSISTENCIES = [:always, :sticky, :delayed].freeze
  DEFAULT_DATA_CONSISTENCY = :always

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

  class_methods do
    def feature_category(value, *extras)
      raise "Invalid category. Use `feature_category_not_owned!` to mark a worker as not owned" if value == :not_owned

      set_class_attribute(:feature_category, value)
    end

    # Special case: mark this work as not associated with a feature category
    # this should be used for cross-cutting concerns, such as mailer workers.
    def feature_category_not_owned!
      set_class_attribute(:feature_category, :not_owned)
    end

    def get_feature_category
      get_class_attribute(:feature_category)
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
      class_attributes[:urgency] || :low
    end

    # Allows configuring worker's data_consistency.
    #
    #  Worker can utilize Sidekiq readonly database replicas capabilities by setting data_consistency attribute.
    #  Workers with data_consistency set to :delayed or :sticky, calling #perform_async
    #  will be delayed in order to give replication process enough time to complete.
    #
    #  - *data_consistency* values:
    #    - 'always' - The job is required to use the primary database (default).
    #    - 'sticky' - The uses a replica as long as possible. It switches to primary either on write or long replication lag.
    #    - 'delayed' - The job would switch to primary only on write. It would use replica always.
    #      If there's a long replication lag the job will be delayed, and only if the replica is not up to date on the next retry,
    #      it will switch to the primary.
    #  - *feature_flag* - allows you to toggle a job's `data_consistency, which permits you to safely toggle load balancing capabilities for a specific job.
    #    If disabled, job will default to `:always`, which means that the job will always use the primary.
    def data_consistency(data_consistency, feature_flag: nil)
      raise ArgumentError, "Invalid data consistency: #{data_consistency}" unless VALID_DATA_CONSISTENCIES.include?(data_consistency)
      raise ArgumentError, 'Data consistency is already set' if class_attributes[:data_consistency]

      set_class_attribute(:data_consistency_feature_flag, feature_flag) if feature_flag
      set_class_attribute(:data_consistency, data_consistency)

      validate_worker_attributes!
    end

    def validate_worker_attributes!
      # Since the deduplication should always take into account the latest binary replication pointer into account,
      # not the first one, the deduplication will not work with sticky or delayed.
      # Follow up issue to improve this: https://gitlab.com/gitlab-org/gitlab/-/issues/325291
      if idempotent? && utilizes_load_balancing_capabilities?
        raise ArgumentError, "Class can't be marked as idempotent if data_consistency is not set to :always"
      end
    end

    # If data_consistency is not set to :always, worker will try to utilize load balancing capabilities and use the replica
    def utilizes_load_balancing_capabilities?
      get_data_consistency != :always
    end

    def get_data_consistency
      class_attributes[:data_consistency] || DEFAULT_DATA_CONSISTENCY
    end

    def get_data_consistency_feature_flag_enabled?
      return true unless class_attributes[:data_consistency_feature_flag]

      Feature.enabled?(class_attributes[:data_consistency_feature_flag], default_enabled: :yaml)
    end

    # Set this attribute on a job when it will call to services outside of the
    # application, such as 3rd party applications, other k8s clusters etc See
    # doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies for
    # details
    def worker_has_external_dependencies!
      set_class_attribute(:external_dependencies, true)
    end

    # Returns a truthy value if the worker has external dependencies.
    # See doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies
    # for details
    def worker_has_external_dependencies?
      class_attributes[:external_dependencies]
    end

    def worker_resource_boundary(boundary)
      raise "Invalid boundary" unless VALID_RESOURCE_BOUNDARIES.include? boundary

      set_class_attribute(:resource_boundary, boundary)
    end

    def get_worker_resource_boundary
      class_attributes[:resource_boundary] || :unknown
    end

    def idempotent!
      set_class_attribute(:idempotent, true)

      validate_worker_attributes!
    end

    def idempotent?
      class_attributes[:idempotent]
    end

    def weight(value)
      set_class_attribute(:weight, value)
    end

    def get_weight
      class_attributes[:weight] ||
        NAMESPACE_WEIGHTS[queue_namespace] ||
        1
    end

    def tags(*values)
      set_class_attribute(:tags, values)
    end

    def get_tags
      Array(class_attributes[:tags])
    end

    def deduplicate(strategy, options = {})
      set_class_attribute(:deduplication_strategy, strategy)
      set_class_attribute(:deduplication_options, options)
    end

    def get_deduplicate_strategy
      class_attributes[:deduplication_strategy] ||
        Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob::DEFAULT_STRATEGY
    end

    def get_deduplication_options
      class_attributes[:deduplication_options] || {}
    end

    def deduplication_enabled?
      return true unless get_deduplication_options[:feature_flag]

      Feature.enabled?(get_deduplication_options[:feature_flag], default_enabled: :yaml)
    end

    def big_payload!
      set_class_attribute(:big_payload, true)
    end

    def big_payload?
      class_attributes[:big_payload]
    end
  end
end
