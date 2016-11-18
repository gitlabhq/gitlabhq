module Gitlab
  module CycleAnalytics
    class StagingStage < BaseStage
      def median
        @fetcher.calculate_metric(:staging,
                                  MergeRequest::Metrics.arel_table[:merged_at],
                                  MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
      end
    end
  end
end
