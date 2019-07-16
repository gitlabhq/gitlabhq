# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module RedisCounter
      def increment
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      def total_count
        Gitlab::Redis::SharedState.with { |redis| redis.get(redis_counter_key).to_i }
      end

      def redis_counter_key
        raise NotImplementedError
      end
    end
  end
end
