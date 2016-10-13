module Gitlab
  module CycleAnalytics
    class Events
      def initialize(project:, from:)
        @project = project
        @from = from
        @fetcher = EventsFetcher.new(project: project, from: from)
      end

      def issue_events
        @fetcher.fetch_issues
      end
    end
  end
end
