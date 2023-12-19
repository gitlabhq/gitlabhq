# frozen_string_literal: true

module Gitlab
  module CircuitBreaker
    class Store
      def key?(key)
        with { |redis| redis.exists?(key) }
      end

      def store(key, value, opts = {})
        with do |redis|
          redis.set(key, value, ex: opts[:expires])
          value
        end
      end

      def increment(key, amount = 1, opts = {})
        expires = opts[:expires]

        with do |redis|
          redis.multi do |multi|
            multi.incrby(key, amount)
            multi.expire(key, expires) if expires
          end
        end
      end

      def load(key, _opts = {})
        with { |redis| redis.get(key) }
      end

      def values_at(*keys, **_opts)
        keys.map! { |key| load(key) }
      end

      def delete(key)
        with { |redis| redis.del(key) }
      end

      private

      def with(&block)
        Gitlab::Redis::RateLimiting.with(&block)
      rescue ::Redis::BaseConnectionError
        # Do not raise an error if we cannot connect to Redis. If
        # Redis::RateLimiting is unavailable it should not take the site down.
        nil
      end
    end
  end
end
