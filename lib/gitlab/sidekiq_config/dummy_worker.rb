# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    # For queues that don't have explicit workers - default and mailers
    class DummyWorker
      attr_accessor :queue

      ATTRIBUTE_METHODS = {
        feature_category: :get_feature_category,
        has_external_dependencies: :worker_has_external_dependencies?,
        latency_sensitive: :latency_sensitive_worker?,
        resource_boundary: :get_worker_resource_boundary,
        idempotent: :idempotent?,
        weight: :get_weight
      }.freeze

      def initialize(queue, attributes = {})
        @queue = queue
        @attributes = attributes
      end

      def queue_namespace
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
