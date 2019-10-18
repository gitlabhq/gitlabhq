# frozen_string_literal: true

module WorkerAttributes
  extend ActiveSupport::Concern

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
