# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementResourceUsagePerAction < BaseStrategy
      def initialize(key)
        @usage = ::Gitlab::SafeRequestStore[key].to_f
      end

      def increment(cache_key, expiry)
        with_redis do |redis|
          redis.pipelined do |pipeline|
            pipeline.incrbyfloat(cache_key, @usage)
            pipeline.expire(cache_key, expiry)
          end.first
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
