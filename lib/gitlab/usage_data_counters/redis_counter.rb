# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module RedisCounter
      include Gitlab::Utils::StrongMemoize

      # This file overrides (or aliases) some keys for legacy Redis metric counters to delay migrating them to new
      # names for now, because doing that in bulk will be a lot easier.
      KEY_OVERRIDES_PATH = Rails.root.join('lib/gitlab/usage_data_counters/total_counter_redis_key_overrides.yml')

      def increment(redis_counter_key)
        legacy_redis_counter_key = legacy_key(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(legacy_redis_counter_key) }
      end

      def increment_by(redis_counter_key, incr)
        legacy_redis_counter_key = legacy_key(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.incrby(legacy_redis_counter_key, incr) }
      end

      def total_count(redis_counter_key)
        legacy_redis_counter_key = legacy_key(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(legacy_redis_counter_key).to_i }
      end

      private

      def legacy_key(redis_key)
        key_overrides.fetch(redis_key, redis_key)
      end

      def key_overrides
        YAML.safe_load(File.read(KEY_OVERRIDES_PATH))
      end
      strong_memoize_attr :key_overrides
    end
  end
end
