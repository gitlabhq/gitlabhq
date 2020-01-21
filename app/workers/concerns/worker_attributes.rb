# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern

  # Resource boundaries that workers can declare through the
  # `worker_resource_boundary` attribute
  VALID_RESOURCE_BOUNDARIES = [:memory, :cpu, :unknown].freeze

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

    # This should be set for jobs that need to be run immediately, or, if
    # they are delayed, risk creating inconsistencies in the application
    # that could being perceived by the user as incorrect behavior
    # (ie, a bug)
    # See doc/development/sidekiq_style_guide.md#Latency-Sensitive-Jobs
    # for details
    def latency_sensitive_worker!
      worker_attributes[:latency_sensitive] = true
    end

    # Returns a truthy value if the worker is latency sensitive.
    # See doc/development/sidekiq_style_guide.md#Latency-Sensitive-Jobs
    # for details
    def latency_sensitive_worker?
      worker_attributes[:latency_sensitive]
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
