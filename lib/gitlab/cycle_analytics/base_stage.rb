module Gitlab
  module CycleAnalytics
    class BaseStage
      include ClassNameUtil

      def initialize(project:, options:)
        @project = project
        @options = options
        @fetcher = Gitlab::CycleAnalytics::MetricsFetcher.new(project: project,
                                                              from: options[:from],
                                                              branch: options[:branch])
      end

      def events
        Gitlab::CycleAnalytics::Event[stage].new(fetcher: @fetcher, options: @options).fetch
      end

      def median_data
        AnalyticsStageSerializer.new.represent(self).as_json
      end

      def title
        stage.to_s.capitalize
      end

      def median
        raise NotImplementedError.new("Expected #{self.name} to implement median")
      end

      private

      def stage
        class_name_for('Stage')
      end
    end
  end
end
