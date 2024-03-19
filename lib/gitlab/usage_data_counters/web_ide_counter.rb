# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class WebIdeCounter < BaseCounter
      KNOWN_EVENTS = %w[commits views merge_requests previews previews_success terminals pipelines].freeze
      PREFIX = 'web_ide'

      class << self
        def increment_commits_count
          count('commits')
        end

        def increment_merge_requests_count
          count('merge_requests')
        end

        def increment_terminals_count
          count('terminals')
        end

        def increment_pipelines_count
          count('pipelines')
        end

        private

        def redis_key(event)
          require_known_event(event)

          "#{prefix}_#{event}_count".upcase
        end
      end
    end
  end
end
