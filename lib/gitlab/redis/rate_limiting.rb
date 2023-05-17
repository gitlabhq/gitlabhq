# frozen_string_literal: true

module Gitlab
  module Redis
    class RateLimiting < ::Gitlab::Redis::Wrapper
      # We create a subclass only for the purpose of differentiating between different stores in cache metrics
      RateLimitingStore = Class.new(ActiveSupport::Cache::RedisCacheStore)

      class << self
        # The data we store on RateLimiting used to be stored on Cache.
        def config_fallback
          Cache
        end

        def cache_store
          @cache_store ||= RateLimitingStore.new(redis: pool, namespace: Cache::CACHE_NAMESPACE)
        end
      end
    end
  end
end
