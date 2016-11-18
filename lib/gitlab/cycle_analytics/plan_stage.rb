module Gitlab
  module CycleAnalytics
    class PlanStage < BaseStage
      def median
        @fetcher.calculate_metric(:plan,
                                  [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                                   Issue::Metrics.arel_table[:first_added_to_board_at]],
                                  Issue::Metrics.arel_table[:first_mentioned_in_commit_at])
      end
    end
  end
end
