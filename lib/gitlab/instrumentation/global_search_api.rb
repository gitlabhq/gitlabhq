# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class GlobalSearchApi
      TYPE = 'meta.search.type'
      LEVEL = 'meta.search.level'
      SCOPE = 'meta.search.scope'
      SEARCH_DURATION_S = :global_search_duration_s

      def self.get_type
        ::Gitlab::SafeRequestStore[TYPE]
      end

      def self.get_level
        ::Gitlab::SafeRequestStore[LEVEL]
      end

      def self.get_scope
        ::Gitlab::SafeRequestStore[SCOPE]
      end

      def self.get_search_duration_s
        ::Gitlab::SafeRequestStore[SEARCH_DURATION_S]
      end

      def self.payload
        {
          TYPE => get_type,
          LEVEL => get_level,
          SCOPE => get_scope,
          SEARCH_DURATION_S => get_search_duration_s
        }.compact
      end

      def self.set_information(type:, level:, scope:, search_duration_s:)
        if ::Gitlab::SafeRequestStore.active?
          ::Gitlab::SafeRequestStore[TYPE] = type
          ::Gitlab::SafeRequestStore[LEVEL] = level
          ::Gitlab::SafeRequestStore[SCOPE] = scope
          ::Gitlab::SafeRequestStore[SEARCH_DURATION_S] = search_duration_s
        end
      end
    end
  end
end
