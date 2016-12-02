module Gitlab
  module CycleAnalytics
    class TestStage < BaseStage
      def initialize(*args)
        @start_time_attrs =  mr_metrics_table[:latest_build_started_at]
        @end_time_attrs = mr_metrics_table[:latest_build_finished_at]

        super(*args)
      end

      def stage
        :test
      end

      def description
        "Total test time for all commits/merges"
      end
    end
  end
end
