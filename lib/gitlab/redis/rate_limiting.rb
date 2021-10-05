# frozen_string_literal: true

module Gitlab
  module Redis
    class RateLimiting < ::Gitlab::Redis::Wrapper
      # The data we store on RateLimiting used to be stored on Cache.
      def self.config_fallback
        Cache
      end

      def self.cache_store
        @cache_store ||= ActiveSupport::Cache::RedisCacheStore.new(redis: pool, namespace: Cache::CACHE_NAMESPACE)
      end
    end
  end
end
