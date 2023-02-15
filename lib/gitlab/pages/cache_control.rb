# frozen_string_literal: true

require 'set'

module Gitlab
  module Pages
    class CacheControl
      include Gitlab::Utils::StrongMemoize

      EXPIRE = 12.hours
      # To avoid delivering expired deployment URL in the cached payload,
      # use a longer expiration time in the deployment URL
      DEPLOYMENT_EXPIRATION = (EXPIRE + 12.hours)

      SETTINGS_CACHE_KEY = 'pages_domain_for_%{type}_%{id}'
      PAYLOAD_CACHE_KEY = '%{settings_cache_key}_%{settings_hash}'

      class << self
        def for_domain(domain_id)
          new(type: :domain, id: domain_id)
        end

        def for_namespace(namespace_id)
          new(type: :namespace, id: namespace_id)
        end
      end

      def initialize(type:, id:)
        raise(ArgumentError, "type must be :namespace or :domain") unless %i[namespace domain].include?(type)

        @type = type
        @id = id
      end

      def cache_key
        strong_memoize(:payload_cache_key) do
          cache_settings_hash!

          payload_cache_key_for(settings_hash)
        end
      end

      # Invalidates the cache.
      #
      # Since rails nodes and sidekiq nodes have different application settings,
      # and the invalidation happens in a sidekiq node, we have to use the
      # cached settings hash to build the payload cache key to be invalidated.
      def clear_cache
        keys = cached_settings_hashes
         .map { |hash| payload_cache_key_for(hash) }
         .push(settings_cache_key)

        ::Gitlab::AppLogger.info(
          message: 'clear pages cache',
          pages_keys: keys,
          pages_type: @type,
          pages_id: @id
        )

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          Rails.cache.delete_multi(keys)
        end
      end

      private

      # Since rails nodes and sidekiq nodes have different application settings,
      # we cache the application settings hash when creating the payload cache
      # so we can use these values to invalidate the cache in a sidekiq node later.
      def cache_settings_hash!
        cached = cached_settings_hashes.to_set
        Rails.cache.write(settings_cache_key, cached.add(settings_hash))
      end

      def cached_settings_hashes
        Rails.cache.read(settings_cache_key) || []
      end

      def payload_cache_key_for(settings_hash)
        PAYLOAD_CACHE_KEY % {
          settings_cache_key: settings_cache_key,
          settings_hash: settings_hash
        }
      end

      def settings_cache_key
        strong_memoize(:settings_cache_key) do
          SETTINGS_CACHE_KEY % { type: @type, id: @id }
        end
      end

      def settings_hash
        strong_memoize(:settings_hash) do
          values = ::Gitlab.config.pages.dup

          values['app_settings'] = ::Gitlab::CurrentSettings.attributes.slice(
            'force_pages_access_control'
          )

          ::Digest::SHA256.hexdigest(values.inspect)
        end
      end
    end
  end
end
