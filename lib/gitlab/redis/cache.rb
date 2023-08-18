# frozen_string_literal: true

module Gitlab
  module Redis
    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'

      class << self
        # Full list of options:
        # https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-c-new
        # pool argument event not documented in the link above is handled by RedisCacheStore see:
        # https://github.com/rails/rails/blob/593893c901f87b4ed205751f72df41519b4d2da3/activesupport/lib/active_support/cache/redis_cache_store.rb#L165
        # and
        # https://github.com/rails/rails/blob/ad790cb2f6bc724a89e4266b505b3c57d5089dae/activesupport/lib/active_support/cache.rb#L206
        def active_support_config
          {
            redis: pool,
            pool: false,
            compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
            namespace: CACHE_NAMESPACE,
            expires_in: default_ttl_seconds
          }
        end

        def default_ttl_seconds
          ENV.fetch('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS', 8.hours).to_i
        end
      end
    end
  end
end
