# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern

  # Resource boundaries that workers can declare through the
  # `resource_boundary` attribute
  VALID_RESOURCE_BOUNDARIES = [:memory, :cpu, :unknown].freeze

  # Urgencies that workers can declare through the `urgencies` attribute
  VALID_URGENCIES = [:high, :low, :throttled].freeze

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
    def feature_category(value)
      raise "Invalid category. Use `feature_category_not_owned!` to mark a worker as not owned" if value == :not_owned

      worker_attributes[:feature_category] = value
    end

    # Special case: mark this work as not associated with a feature category
    # this should be used for cross-cutting concerns, such as mailer workers.
    def feature_category_not_owned!
      worker_attributes[:feature_category] = :not_owned
    end

    def get_feature_category
      get_worker_attribute(:feature_category)
    end

    def feature_category_not_owned?
      get_worker_attribute(:feature_category) == :not_owned
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

      worker_attributes[:urgency] = urgency
    end

    def get_urgency
      worker_attributes[:urgency] || :low
    end

    # Set this attribute on a job when it will call to services outside of the
    # application, such as 3rd party applications, other k8s clusters etc See
    # doc/development/sidekiq_style_guide.md#Jobs-with-External-Dependencies for
    # details
    def worker_has_external_dependencies!
      worker_attributes[:external_dependencies] = true
    end

    # Returns a truthy value if the worker has external dependencies.
    # See doc/development/sidekiq_style_guide.md#Jobs-with-External-Dependencies
    # for details
    def worker_has_external_dependencies?
      worker_attributes[:external_dependencies]
    end

    def worker_resource_boundary(boundary)
      raise "Invalid boundary" unless VALID_RESOURCE_BOUNDARIES.include? boundary

      worker_attributes[:resource_boundary] = boundary
    end

    def get_worker_resource_boundary
      worker_attributes[:resource_boundary] || :unknown
    end

    def idempotent!
      worker_attributes[:idempotent] = true
    end

    def idempotent?
      worker_attributes[:idempotent]
    end

    def weight(value)
      worker_attributes[:weight] = value
    end

    def get_weight
      worker_attributes[:weight] ||
        NAMESPACE_WEIGHTS[queue_namespace] ||
        1
    end

    def tags(*values)
      worker_attributes[:tags] = values
    end

    def get_tags
      Array(worker_attributes[:tags])
    end

    protected

    # Returns a worker attribute declared on this class or its parent class.
    # This approach allows declared attributes to be inherited by
    # child classes.
    def get_worker_attribute(name)
      worker_attributes[name] || superclass_worker_attributes(name)
    end

    private

    def worker_attributes
      @attributes ||= {}
    end

    def superclass_worker_attributes(name)
      return unless superclass.include? WorkerAttributes

      superclass.get_worker_attribute(name)
    end
  end
end
