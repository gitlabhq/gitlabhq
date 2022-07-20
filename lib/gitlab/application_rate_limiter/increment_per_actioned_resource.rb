# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementPerActionedResource < BaseStrategy
      def initialize(resource_key)
        @resource_key = resource_key
      end

      def increment(cache_key, expiry)
        with_redis do |redis|
          redis.pipelined do
            redis.sadd(cache_key, resource_key)
            redis.expire(cache_key, expiry)
            redis.scard(cache_key)
          end.last
        end
      end

      def read(cache_key)
        with_redis do |redis|
          redis.scard(cache_key)
        end
      end

      private

      attr_accessor :resource_key
    end
  end
end
