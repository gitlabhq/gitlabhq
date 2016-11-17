module Gitlab
  module CycleAnalytics
    class EventsFetcher
      def initialize(project:, options:)
        @query = EventsQuery.new(project: project, options: options)
      end

      def fetch(stage:)
        @query.execute(stage)
      end
    end
  end
end
