# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module RedisCounter
      def increment(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def total_count(redis_counter_key)
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_counter_key).to_i }
      end
    end
  end
end
