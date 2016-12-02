module Gitlab
  module CycleAnalytics
    class BaseStage
      attr_accessor :start_time_attrs, :end_time_attrs

      def initialize(project:, options:)
        @project = project
        @options = options
        @fetcher = Gitlab::CycleAnalytics::MetricsFetcher.new(project: project,
                                                              from: options[:from],
                                                              branch: options[:branch],
                                                              stage: self)
      end

      def event
        @event ||= Gitlab::CycleAnalytics::Event[stage].new(fetcher: @fetcher, options: @options)
      end

      def events
        event.fetch
      end

      def median_data
        AnalyticsStageSerializer.new.represent(self).as_json
      end

      def title
        stage.to_s.capitalize
      end

      def median
        @fetcher.median
      end

      private

      def stage
        class_name_for('Stage')
      end
    end
  end
end
