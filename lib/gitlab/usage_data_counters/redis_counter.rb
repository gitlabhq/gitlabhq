# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module RedisCounter
      def increment(redis_counter_key)
        return unless Gitlab::CurrentSettings.usage_ping_enabled

        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def increment_by(redis_counter_key, incr)
        return unless Gitlab::CurrentSettings.usage_ping_enabled

        Gitlab::Redis::SharedState.with { |redis| redis.incrby(redis_counter_key, incr) }
      end

      def total_count(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_counter_key).to_i }
      end
    end
  end
end
