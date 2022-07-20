# frozen_string_literal: true

module Gitlab
  module Pages
    class CacheControl
      CACHE_KEY_FORMAT = 'pages_domain_for_%{type}_%{id}'

      attr_reader :cache_key

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

        @cache_key = CACHE_KEY_FORMAT % { type: type, id: id }
      end

      def clear_cache
        Rails.cache.delete(cache_key)
      end
    end
  end
end
