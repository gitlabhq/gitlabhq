module Gitlab
  module CycleAnalytics
    class ReviewStage < BaseStage
      def start_time_attrs
        @start_time_attrs ||= mr_table[:created_at]
      end

      def end_time_attrs
        @end_time_attrs ||= mr_metrics_table[:merged_at]
      end

      def name
        :review
      end

      def legend
        "Relative Merged Requests"
      end

      def description
        "Time between merge request creation and merge/close"
      end
    end
  end
end
