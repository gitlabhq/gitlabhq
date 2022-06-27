# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    class BaseStrategy
      # Increment the rate limit count and return the new count value
      def increment(cache_key, expiry)
        raise NotImplementedError
      end

      # Return the rate limit count.
      # Should be 0 if there is no data in the cache.
      def read(cache_key)
        raise NotImplementedError
      end

      private

      def with_redis(&block)
        ::Gitlab::Redis::RateLimiting.with(&block) # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end
