# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module RedisCounter
      def increment(redis_counter_key)
        return unless ::ServicePing::ServicePingSettings.enabled?

        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def increment_by(redis_counter_key, incr)
        return unless ::ServicePing::ServicePingSettings.enabled?

        Gitlab::Redis::SharedState.with { |redis| redis.incrby(redis_counter_key, incr) }
      end

      def total_count(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_counter_key).to_i }
      end
    end
  end
end
