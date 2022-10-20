# frozen_string_literal: true

module Gitlab
  module Pages
    class CacheControl
      include Gitlab::Utils::StrongMemoize

      EXPIRE = 12.hours
      # To avoid delivering expired deployment URL in the cached payload,
      # use a longer expiration time in the deployment URL
      DEPLOYMENT_EXPIRATION = (EXPIRE + 12.hours)
      CACHE_KEY_FORMAT = 'pages_domain_for_%{type}_%{id}_%{settings}'

      class << self
        def for_project(project_id)
          new(type: :project, id: project_id)
        end

        def for_namespace(namespace_id)
          new(type: :namespace, id: namespace_id)
        end
      end

      def initialize(type:, id:)
        raise(ArgumentError, "type must be :namespace or :project") unless %i[namespace project].include?(type)

        @type = type
        @id = id
      end

      def cache_key
        strong_memoize(:cache_key) do
          CACHE_KEY_FORMAT % {
            type: @type,
            id: @id,
            settings: settings
          }
        end
      end

      def clear_cache
        Rails.cache.delete(cache_key)
      end

      private

      def settings
        values = ::Gitlab.config.pages.dup

        values['app_settings'] = ::Gitlab::CurrentSettings.attributes.slice(
          'force_pages_access_control'
        )

        ::Digest::SHA256.hexdigest(values.inspect)
      end
    end
  end
end
