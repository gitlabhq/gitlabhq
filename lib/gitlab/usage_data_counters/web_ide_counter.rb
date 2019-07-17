# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class WebIdeCounter
      extend RedisCounter

      COMMITS_COUNT_KEY = 'WEB_IDE_COMMITS_COUNT'

      class << self
        def increment_commits_count
          increment(COMMITS_COUNT_KEY)
        end

        def total_commits_count
          total_count(COMMITS_COUNT_KEY)
        end
      end
    end
  end
end
