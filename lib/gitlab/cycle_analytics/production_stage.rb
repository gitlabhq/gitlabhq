module Gitlab
  module CycleAnalytics
    class ProductionStage < BaseStage
      def median
        @fetcher.calculate_metric(:production,
                                  Issue.arel_table[:created_at],
                                  MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
      end
    end
  end
end
