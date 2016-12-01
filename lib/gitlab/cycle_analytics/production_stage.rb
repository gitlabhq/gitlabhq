module Gitlab
  module CycleAnalytics
    class ProductionStage < BaseStage
      def description
        "From issue creation until deploy to production"
      end

      def median
        @fetcher.median(:production,
                        Issue.arel_table[:created_at],
                        MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
      end
    end
  end
end
