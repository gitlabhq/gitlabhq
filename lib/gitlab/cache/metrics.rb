# frozen_string_literal: true

# Instrumentation for cache efficiency metrics
module Gitlab
  module Cache
    class Metrics
      DEFAULT_BUCKETS = [0, 1, 5].freeze

      def initialize(cache_metadata)
        @cache_metadata = cache_metadata
      end

      # Increase cache hit counter
      #
      def increment_cache_hit(labels = {})
        counter.increment(base_labels.merge(labels, cache_hit: true))
      end

      # Increase cache miss counter
      #
      def increment_cache_miss(labels = {})
        counter.increment(base_labels.merge(labels, cache_hit: false))
      end

      # Measure the duration of cacheable action
      #
      # @example
      #   observe_cache_generation do
      #     cacheable_action
      #   end
      #
      def observe_cache_generation(labels = {}, &block)
        real_start = Gitlab::Metrics::System.monotonic_time

        value = yield

        histogram.observe(base_labels.merge(labels), Gitlab::Metrics::System.monotonic_time - real_start)

        value
      end

      private

      attr_reader :cache_metadata

      def counter
        @counter ||= Gitlab::Metrics.counter(
          :redis_hit_miss_operations_total,
          "Hit/miss Redis cache counter",
          base_labels
        )
      end

      def histogram
        @histogram ||= Gitlab::Metrics.histogram(
          :redis_cache_generation_duration_seconds,
          'Duration of Redis cache generation',
          base_labels,
          DEFAULT_BUCKETS
        )
      end

      def base_labels
        @base_labels ||= {
          cache_identifier: cache_metadata.cache_identifier,
          feature_category: cache_metadata.feature_category,
          backing_resource: cache_metadata.backing_resource
        }
      end
    end
  end
end
