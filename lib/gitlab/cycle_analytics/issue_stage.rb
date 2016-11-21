module Gitlab
  module CycleAnalytics
    class IssueStage < BaseStage
      def initialize(*args)
        super(*args)

        @description = "Time before an issue gets scheduled"
      end

      def median
        @fetcher.calculate_metric(:issue,
                                  Issue.arel_table[:created_at],
                                  [Issue::Metrics.arel_table[:first_associated_with_milestone_at],
                                   Issue::Metrics.arel_table[:first_added_to_board_at]])
      end
    end
  end
end
