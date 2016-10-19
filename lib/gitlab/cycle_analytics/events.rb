module Gitlab
  module CycleAnalytics
    class Events
      include ActionView::Helpers::DateHelper

      def initialize(project:, from:)
        @project = project
        @from = from
        @fetcher = EventsFetcher.new(project: project, from: from)
      end

      #TODO: backend pagination - specially for commits, etc...

      def issue_events
        #TODO figure out what the frontend needs for displaying the avatar
        @fetcher.fetch_issue_events.each do |event|
          event['total_time'] = distance_of_time_in_words(event['total_time'].to_f)
          event['created_at'] = interval_in_words(event['created_at'])
        end
      end

      def plan_events
        # TODO sort out 1st referenced commit and parse stuff
        @fetcher.fetch_plan_events
      end

      private

      def interval_in_words(diff)
        "#{distance_of_time_in_words(diff.to_f)} ago"
      end
    end
  end
end
