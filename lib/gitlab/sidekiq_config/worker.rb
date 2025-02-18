# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class Worker
      include Comparable

      attr_reader :klass

      delegate :feature_category_not_owned?, :generated_queue_name, :get_feature_category,
        :get_sidekiq_options, :get_tags, :get_urgency, :get_weight,
        :get_worker_resource_boundary, :idempotent?, :queue_namespace, :queue,
        :worker_has_external_dependencies?,
        to: :klass

      def initialize(klass, ee:, jh: false)
        @klass = klass
        @ee = ee
        @jh = jh
      end

      def ee?
        @ee
      end

      def jh?
        @jh
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
        [queue_namespace ? 0 : 1, generated_queue_name]
      end

      # YAML representation
      def encode_with(coder)
        coder.represent_map(nil, to_yaml)
      end

      def to_yaml
        {
          name: generated_queue_name,
          worker_name: klass.name,
          feature_category: get_feature_category,
          has_external_dependencies: worker_has_external_dependencies?,
          urgency: get_urgency,
          resource_boundary: get_worker_resource_boundary,
          weight: get_weight,
          idempotent: idempotent?,
          tags: get_tags&.dup,
          queue_namespace: queue_namespace&.to_sym
        }
      end

      def namespace_and_weight
        [queue_namespace, get_weight]
      end

      def queue_and_weight
        [generated_queue_name, get_weight]
      end

      def retries
        get_sidekiq_options['retry']
      end
    end
  end
end
