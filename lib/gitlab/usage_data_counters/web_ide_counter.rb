# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    class WebIdeCounter
      extend RedisCounter
      KNOWN_EVENTS = %i[commits views merge_requests previews terminals pipelines].freeze
      PREFIX = 'web_ide'

      class << self
        def increment_commits_count
          increment(redis_key('commits'))
        end

        def increment_merge_requests_count
          increment(redis_key('merge_requests'))
        end

        def increment_views_count
          increment(redis_key('views'))
        end

        def increment_terminals_count
          increment(redis_key('terminals'))
        end

        def increment_pipelines_count
          increment(redis_key('pipelines'))
        end

        def increment_previews_count
          return unless Gitlab::CurrentSettings.web_ide_clientside_preview_enabled?

          increment(redis_key('previews'))
        end

        def totals
          KNOWN_EVENTS.map { |event| [counter_key(event), total_count(redis_key(event))] }.to_h
        end

        def fallback_totals
          KNOWN_EVENTS.map { |event| [counter_key(event), -1] }.to_h
        end

        private

        def redis_key(event)
          "#{PREFIX}_#{event}_count".upcase
        end

        def counter_key(event)
          "#{PREFIX}_#{event}".to_sym
        end
      end
    end
  end
end
