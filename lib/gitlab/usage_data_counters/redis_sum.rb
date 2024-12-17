# frozen_string_literal: true

# WARNING: This module has been deprecated and will be removed in the future
# Use InternalEvents.track_event instead https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/index.html

module Gitlab
  module UsageDataCounters
    module RedisSum
      def increment_sum_by(redis_counter_key, incr, expiry: nil)
        Gitlab::Redis::SharedState.with do |redis|
          redis.incrbyfloat(redis_counter_key, incr)

          unless expiry.nil?
            existing_expiry = redis.ttl(redis_counter_key) > 0
            redis.expire(redis_counter_key, expiry) unless existing_expiry
          end
        end
      end

      def get(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_counter_key).to_f }
      end
    end
  end
end
