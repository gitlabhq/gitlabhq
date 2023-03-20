# frozen_string_literal: true

module Gitlab
  module RackAttack
    class Store
      InvalidAmount = Class.new(StandardError)

      # The increment method gets called very often. The implementation below
      # aims to minimize the number of Redis calls we make.
      def increment(key, amount = 1, options = {})
        # Our code below that prevents calling EXPIRE after every INCR assumes
        # we always increment by 1. This is true in Rack::Attack as of v6.6.1.
        # This guard should alert us if Rack::Attack changes its behavior in a
        # future version.
        raise InvalidAmount unless amount == 1

        with do |redis|
          key = namespace(key)
          new_value = redis.incr(key)
          expires_in = options[:expires_in]
          redis.expire(key, expires_in) if new_value == 1 && expires_in
          new_value
        end
      end

      def read(key, _options = {})
        with { |redis| redis.get(namespace(key)) }
      end

      def write(key, value, options = {})
        with { |redis| redis.set(namespace(key), value, ex: options[:expires_in]) }
      end

      def delete(key, _options = {})
        with { |redis| redis.del(namespace(key)) }
      end

      private

      def with(&block)
        # rubocop: disable CodeReuse/ActiveRecord
        Gitlab::Redis::RateLimiting.with(&block)
        # rubocop: enable CodeReuse/ActiveRecord
      rescue ::Redis::BaseConnectionError
        # Following the example of
        # https://github.com/rack/rack-attack/blob/v6.6.1/lib/rack/attack/store_proxy/redis_proxy.rb#L61-L65,
        # do not raise an error if we cannot connect to Redis. If
        # Redis::RateLimiting is unavailable it should not take the site down.
        nil
      end

      def namespace(key)
        "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{key}"
      end
    end
  end
end
