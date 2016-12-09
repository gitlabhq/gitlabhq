module Gitlab
  module CycleAnalytics
    class ProductionStage < BaseStage
      include ProductionHelper

      def initialize(*args)
        @start_time_attrs = issue_table[:created_at]
        @end_time_attrs = mr_metrics_table[:first_deployed_to_production_at]

        super(*args)
      end

      def name
        :production
      end

      def description
        "From issue creation until deploy to production"
      end

      def query
        # Limit to merge requests that have been deployed to production after `@from`
        query.where(mr_metrics_table[:first_deployed_to_production_at].gteq(@from))
      end
    end
  end
end
