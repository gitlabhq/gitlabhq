# frozen_string_literal: true

module Gitlab
  module Redis
    class RepositoryCache < ::Gitlab::Redis::Wrapper
      class << self
        # The data we store on RepositoryCache used to be stored on Cache.
        def config_fallback
          Cache
        end

        def cache_store
          @cache_store ||= ActiveSupport::Cache::RedisCacheStore.new(
            redis: pool,
            compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
            namespace: Cache::CACHE_NAMESPACE,
            # Cache should not grow forever
            expires_in: ENV.fetch('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS', 8.hours).to_i
          )
        end

        private

        def redis
          primary_store = ::Redis.new(params)
          secondary_store = ::Redis.new(config_fallback.params)

          MultiStore.new(primary_store, secondary_store, store_name)
        end
      end
    end
  end
end
