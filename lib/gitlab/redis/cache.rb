# frozen_string_literal: true

module Gitlab
  module Redis
    # Match signature in
    # https://github.com/rails/rails/blob/v6.1.7.2/activesupport/lib/active_support/cache/redis_cache_store.rb#L59
    ERROR_HANDLER = ->(method:, returning:, exception:) do
      Gitlab::ErrorTracking.log_exception(
        exception,
        method: method,
        returning: returning.inspect
      )
    end

    class Cache < ::Gitlab::Redis::Wrapper
      CACHE_NAMESPACE = 'cache:gitlab'

      # Full list of options:
      # https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-c-new
      def self.active_support_config
        {
          redis: pool,
          compress: Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1')),
          namespace: CACHE_NAMESPACE,
          expires_in: default_ttl_seconds,
          error_handler: ::Gitlab::Redis::ERROR_HANDLER
        }
      end

      def self.default_ttl_seconds
        ENV.fetch('GITLAB_RAILS_CACHE_DEFAULT_TTL_SECONDS', 8.hours).to_i
      end
    end
  end
end
