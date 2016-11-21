module Gitlab
  module CycleAnalytics
    class BaseStage
      attr_reader :stage, :description

      def initialize(project:, options:, stage: stage)
        @project = project
        @options = options
        @fetcher = Gitlab::CycleAnalytics::MetricsFetcher.new(project: project,
                                                              from: options[:from],
                                                              branch: options[:branch])
        @stage = stage
      end

      def events
        event_class.new(fetcher: @fetcher, stage: @stage).fetch
      end

      private

      def event_class
        "Gitlab::CycleAnalytics::#{@stage.to_s.capitalize}Event".constantize
      end
    end
  end
end
