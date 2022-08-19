# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementPerAction < BaseStrategy
      def increment(cache_key, expiry)
        with_redis do |redis|
          redis.pipelined do |pipeline|
            pipeline.incr(cache_key)
            pipeline.expire(cache_key, expiry)
          end.first
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
