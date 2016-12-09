module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def initialize(*args)
        @start_time_attrs =  mr_metrics_table[:latest_build_started_at]
        @end_time_attrs = mr_metrics_table[:latest_build_finished_at]

        super(*args)
      end

      def name
        :test
      end

      def description
        "Total test time for all commits/merges"
      end

      def stage_query
        if @options[:branch]
          super.where(build_table[:ref].eq(@options[:branch]))
        else
          super
        end
      end
    end
  end
end
