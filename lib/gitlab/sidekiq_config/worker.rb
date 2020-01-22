# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class Worker
      include Comparable

      attr_reader :klass
      delegate :feature_category_not_owned?, :get_feature_category,
               :get_worker_resource_boundary, :latency_sensitive_worker?,
               :queue, :worker_has_external_dependencies?,
               to: :klass

      def initialize(klass, ee:)
        @klass = klass
        @ee = ee
      end

      def ee?
        @ee
      end

      def ==(other)
        to_yaml == case other
                   when self.class
                     other.to_yaml
                   else
                     other
                   end
      end

      def <=>(other)
        to_sort <=> other.to_sort
      end

      # Put namespaced queues first
      def to_sort
        [queue.include?(':') ? 0 : 1, queue]
      end

      # YAML representation
      def encode_with(coder)
        coder.represent_scalar(nil, to_yaml)
      end

      def to_yaml
        queue
      end
    end
  end
end
