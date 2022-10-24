# frozen_string_literal: true

# Instrumentation for cache efficiency metrics
module Gitlab
  module Cache
    class Metrics
      DEFAULT_BUCKETS = [0, 1, 5].freeze
      VALID_BACKING_RESOURCES = [:cpu, :database, :gitaly, :memory, :unknown].freeze
      DEFAULT_BACKING_RESOURCE = :unknown

      def initialize(
        caller_id:,
        cache_identifier:,
        feature_category: ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT,
        backing_resource: DEFAULT_BACKING_RESOURCE
      )
        @caller_id = caller_id
        @cache_identifier = cache_identifier
        @feature_category = Gitlab::FeatureCategories.default.get!(feature_category)
        @backing_resource = fetch_backing_resource!(backing_resource)
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

      attr_reader :caller_id, :cache_identifier, :feature_category, :backing_resource

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
          caller_id: caller_id,
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        }
      end

      def fetch_backing_resource!(resource)
        return resource if VALID_BACKING_RESOURCES.include?(resource)

        raise "Unknown backing resource: #{resource}" if Gitlab.dev_or_test_env?

        DEFAULT_BACKING_RESOURCE
      end
    end
  end
end
