module Gitlab
  module CycleAnalytics
    class StagingStage < BaseStage
      def initialize(*args)
        super(*args)

        @description = "From merge request merge until deploy to production"
      end

      def median
        @fetcher.calculate_metric(:staging,
                                  MergeRequest::Metrics.arel_table[:merged_at],
                                  MergeRequest::Metrics.arel_table[:first_deployed_to_production_at])
      end
    end
  end
end
