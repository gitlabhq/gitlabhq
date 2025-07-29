# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class IncrementPerActionedResource < BaseStrategy
      def initialize(resource_key)
        @resource_key = resource_key
      end

      def increment(cache_key, expiry)
        with_redis do |redis|
          added, new_value = redis.pipelined do |pipeline|
            pipeline.sadd?(cache_key, resource_key)
            pipeline.scard(cache_key)
          end

          redis.expire(cache_key, expiry) if added && new_value == 1

          new_value
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
