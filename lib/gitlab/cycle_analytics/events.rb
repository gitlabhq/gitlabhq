module Gitlab
  module CycleAnalytics
    class Events
      def initialize(project:, options:)
        @project = project
        @options = options
      end

      def issue_events
        IssueEvent.new(project: @project, options: @options).fetch
      end

      def plan_events
        PlanEvent.new(project: @project, options: @options).fetch
      end

      def code_events
        CodeEvent.new(project: @project, options: @options).fetch
      end

      def test_events
        TestEvent.new(project: @project, options: @options).fetch
      end

      def review_events
        ReviewEvent.new(project: @project, options: @options).fetch
      end

      def staging_events
        StagingEvent.new(project: @project, options: @options).fetch
      end

      def production_events
        ProductionEvent.new(project: @project, options: @options).fetch
      end
    end
  end
end
