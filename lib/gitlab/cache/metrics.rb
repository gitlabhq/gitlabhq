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
      def increment_cache_hit
        counter.increment(labels.merge(cache_hit: true))
      end

      # Increase cache miss counter
      #
      def increment_cache_miss
        counter.increment(labels.merge(cache_hit: false))
      end

      # Measure the duration of cacheable action
      #
      # @example
      #   observe_cache_generation do
      #     cacheable_action
      #   end
      #
      def observe_cache_generation(&block)
        real_start = Gitlab::Metrics::System.monotonic_time

        value = yield

        histogram.observe({}, Gitlab::Metrics::System.monotonic_time - real_start)

        value
      end

      private

      attr_reader :cache_metadata

      def counter
        @counter ||= Gitlab::Metrics.counter(:redis_hit_miss_operations_total, "Hit/miss Redis cache counter")
      end

      def histogram
        @histogram ||= Gitlab::Metrics.histogram(
          :redis_cache_generation_duration_seconds,
          'Duration of Redis cache generation',
          labels,
          DEFAULT_BUCKETS
        )
      end

      def labels
        @labels ||= {
          cache_identifier: cache_metadata.cache_identifier,
          feature_category: cache_metadata.feature_category,
          backing_resource: cache_metadata.backing_resource
        }
      end
    end
  end
end
