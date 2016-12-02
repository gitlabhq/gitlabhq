module Gitlab
  module CycleAnalytics
    class StagingStage < BaseStage
      def initialize(*args)
        @start_time_attrs = mr_metrics_table[:merged_at]
        @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]

        super(*args)
      end

      def stage
        :staging
      end

      def description
        "From merge request merge until deploy to production"
      end
    end
  end
end
