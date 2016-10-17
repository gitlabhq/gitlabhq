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
          event['issue_diff'] = distance_of_time_in_words(event['issue_diff'].to_f)
        end
      end
    end
  end
end
