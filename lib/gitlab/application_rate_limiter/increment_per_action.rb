# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementPerAction < BaseStrategy
      def increment(cache_key, expiry)
        if Feature.enabled?(:optimize_rate_limiter_redis_expiry, :instance)
          with_redis do |redis|
            new_value = redis.incr(cache_key)

            redis.expire(cache_key, expiry) if new_value == 1

            new_value
          end
        else
          with_redis do |redis|
            redis.pipelined do |pipeline|
              pipeline.incr(cache_key)
              pipeline.expire(cache_key, expiry)
            end.first
          end
        end
      end

      def read(cache_key)
        with_redis do |redis|
          redis.get(cache_key).to_i
        end
      end
    end
  end
end
