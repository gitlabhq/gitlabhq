# frozen_string_literal: true

module Gitlab
  module Instrumentation
    class GlobalSearchApi
      TYPE = 'meta.search.type'
      LEVEL = 'meta.search.level'
      SCOPE = 'meta.search.scope'
      SEARCH_DURATION_S = :global_search_duration_s

      InstrumentationStorage = ::Gitlab::Instrumentation::Storage

      def self.get_type
        InstrumentationStorage[TYPE]
      end

      def self.get_level
        InstrumentationStorage[LEVEL]
      end

      def self.get_scope
        InstrumentationStorage[SCOPE]
      end

      def self.get_search_duration_s
        InstrumentationStorage[SEARCH_DURATION_S]
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
        if InstrumentationStorage.active?
          InstrumentationStorage[TYPE] = type
          InstrumentationStorage[LEVEL] = level
          InstrumentationStorage[SCOPE] = scope
          InstrumentationStorage[SEARCH_DURATION_S] = search_duration_s
        end
      end
    end
  end
end
