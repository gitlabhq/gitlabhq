module Gitlab
  module CycleAnalytics
    class ReviewStage < BaseStage
      def initialize(*args)
        @start_time_attrs = mr_table[:created_at]
        @end_time_attrs = mr_metrics_table[:merged_at]

        super(*args)
      end

      def stage
        :review
      end

      def description
        "Time between merge request creation and merge/close"
      end
    end
  end
end
