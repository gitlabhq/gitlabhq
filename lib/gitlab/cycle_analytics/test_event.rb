module Gitlab
  module CycleAnalytics
    class TestEvent < StagingEvent
      def initialize(*args)
        super(*args)

        @stage = :test
        @start_time_attrs =  mr_metrics_table[:latest_build_started_at]
        @end_time_attrs = mr_metrics_table[:latest_build_finished_at]
      end
    end
  end
end
