# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    # For queues that don't have explicit workers - default and mailers
    class DummyWorker
      ATTRIBUTE_METHODS = {
        name: :name,
        has_external_dependencies: :worker_has_external_dependencies?,
        urgency: :get_urgency,
        resource_boundary: :get_worker_resource_boundary,
        idempotent: :idempotent?,
        weight: :get_weight,
        tags: :get_tags
      }.freeze

      def initialize(attributes = {})
        @attributes = attributes
      end

      def generated_queue_name
        @attributes[:queue]
      end

      def queue
        @attributes[:queue]
      end

      def queue_namespace
        nil
      end

      # All dummy workers are unowned; get the feature category from the
      # context if available.
      def get_feature_category
        Gitlab::ApplicationContext.current_context_attribute('meta.feature_category') || :not_owned
      end

      def feature_category_not_owned?
        true
      end

      def get_worker_context
        nil
      end

      def context_for_arguments(*)
        nil
      end

      ATTRIBUTE_METHODS.each do |attribute, meth|
        define_method meth do
          @attributes[attribute]
        end
      end
    end
  end
end
