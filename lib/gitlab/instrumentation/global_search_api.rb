# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class GlobalSearchApi
      GLOBAL_SEARCH_TYPE = 'meta.search.type'
      GLOBAL_SEARCH_LEVEL = 'meta.search.level'
      GLOBAL_SEARCH_DURATION_S = :global_search_duration_s

      def self.get_global_search_type
        ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_TYPE]
      end

      def self.get_global_search_level
        ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_LEVEL]
      end

      def self.get_global_search_duration_s
        ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_DURATION_S]
      end

      def self.payload
        {
          GLOBAL_SEARCH_TYPE => get_global_search_type,
          GLOBAL_SEARCH_LEVEL => get_global_search_level,
          GLOBAL_SEARCH_DURATION_S => get_global_search_duration_s
        }.compact
      end

      def self.set_global_search_information(global_search_type:, global_search_level:, global_search_duration_s:)
        if ::Gitlab::SafeRequestStore.active?
          ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_TYPE] = global_search_type
          ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_LEVEL] = global_search_level
          ::Gitlab::SafeRequestStore[GLOBAL_SEARCH_DURATION_S] = global_search_duration_s
        end
      end
    end
  end
end
