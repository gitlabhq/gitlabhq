module Gitlab
  module CycleAnalytics
    class Events
      def initialize(project:, options:)
        @project = project
        @query = EventsQuery.new(project: project, options: options)
      end

      def issue_events
        IssueEvent.fetch(@query)
      end

      def plan_events
        PlanEvent.fetch(@query)
      end

      def code_events
        CodeEvent.fetch(@query)
      end

      def test_events
        TestEvent.fetch(@query)
      end

      def review_events
        ReviewEvent.fetch(@query)
      end

      def staging_events
        StagingEvent.fetch(@query)
      end

      def production_events
        ProductionEvent.fetch(@query)
      end
    end
  end
end
