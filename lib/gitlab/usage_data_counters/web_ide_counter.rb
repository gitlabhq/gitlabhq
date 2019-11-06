# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class WebIdeCounter
      extend RedisCounter

      COMMITS_COUNT_KEY = 'WEB_IDE_COMMITS_COUNT'
      MERGE_REQUEST_COUNT_KEY = 'WEB_IDE_MERGE_REQUESTS_COUNT'
      VIEWS_COUNT_KEY = 'WEB_IDE_VIEWS_COUNT'
      PREVIEW_COUNT_KEY = 'WEB_IDE_PREVIEWS_COUNT'

      class << self
        def increment_commits_count
          increment(COMMITS_COUNT_KEY)
        end

        def total_commits_count
          total_count(COMMITS_COUNT_KEY)
        end

        def increment_merge_requests_count
          increment(MERGE_REQUEST_COUNT_KEY)
        end

        def total_merge_requests_count
          total_count(MERGE_REQUEST_COUNT_KEY)
        end

        def increment_views_count
          increment(VIEWS_COUNT_KEY)
        end

        def total_views_count
          total_count(VIEWS_COUNT_KEY)
        end

        def increment_previews_count
          return unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

          increment(PREVIEW_COUNT_KEY)
        end

        def total_previews_count
          total_count(PREVIEW_COUNT_KEY)
        end

        def totals
          {
            web_ide_commits: total_commits_count,
            web_ide_views: total_views_count,
            web_ide_merge_requests: total_merge_requests_count,
            web_ide_previews: total_previews_count
          }
        end
      end
    end
  end
end
