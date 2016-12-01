module Gitlab
  module CycleAnalytics
    class StagingStage < BaseStage
      def description
        "From merge request merge until deploy to production"
      end

      def median
        @fetcher.median(:staging,
                        MergeRequest::Metrics.arel_table[:merged_at],
                        MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
      end
    end
  end
end
