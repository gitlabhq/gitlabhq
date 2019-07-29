# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class SearchCounter
      extend RedisCounter

      NAVBAR_SEARCHES_COUNT_KEY = 'NAVBAR_SEARCHES_COUNT'

      class << self
        def increment_navbar_searches_count
          increment(NAVBAR_SEARCHES_COUNT_KEY)
        end

        def total_navbar_searches_count
          total_count(NAVBAR_SEARCHES_COUNT_KEY)
        end

        def totals
          {
            navbar_searches: total_navbar_searches_count
          }
        end
      end
    end
  end
end
