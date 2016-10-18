module Gitlab
  module CycleAnalytics
    class Events
      include ActionView::Helpers::DateHelper

      def initialize(project:, from:)
        @project = project
        @from = from
        @fetcher = EventsFetcher.new(project: project, from: from)
      end

      def issue_events
        @fetcher.fetch_issues.each do |event|
          event['issue_diff'] = interval_in_words(event['issue_diff'])
          event['created_at'] = interval_in_words(event['created_at'])
        end
      end

      def interval_in_words(diff)
        "#{distance_of_time_in_words( diff.to_f)} ago"
      end
    end
  end
end
