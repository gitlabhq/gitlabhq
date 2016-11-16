module Gitlab
  module CycleAnalytics
    class EventsFetcher
      def initialize(project:, options:)
        @query = EventsQuery.new(project: project, options: options)
      end

      def fetch(stage:)
        @query.execute(stage) do |stage_class, base_query|
          stage_class.query(base_query)
        end
      end
    end
  end
end
