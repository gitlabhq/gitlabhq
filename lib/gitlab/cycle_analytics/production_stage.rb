module Gitlab
  module CycleAnalytics
    class ProductionStage < BaseStage
      def initialize(*args)
        @start_time_attrs = issue_table[:created_at]
        @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]

        super(*args)
      end

      def stage
        :production
      end

      def description
        "From issue creation until deploy to production"
      end
    end
  end
end
