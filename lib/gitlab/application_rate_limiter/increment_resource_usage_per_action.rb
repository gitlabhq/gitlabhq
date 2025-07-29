# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementResourceUsagePerAction < BaseStrategy
      def initialize(key)
        @usage = ::Gitlab::SafeRequestStore[key.to_sym].to_f
      end

      def increment(cache_key, expiry)
        if Feature.enabled?(:optimize_rate_limiter_redis_expiry, :instance)
          return 0 if @usage == 0

          with_redis do |redis|
            new_value = redis.incrbyfloat(cache_key, @usage)

            redis.expire(cache_key, expiry) if new_value == @usage

            new_value
          end
        else
          with_redis do |redis|
            redis.pipelined do |pipeline|
              pipeline.incrbyfloat(cache_key, @usage)
              pipeline.expire(cache_key, expiry)
            end.first
          end
        end
      end

      def read(cache_key)
        with_redis do |redis|
          redis.get(cache_key).to_f
        end
      end
    end
  end
end
