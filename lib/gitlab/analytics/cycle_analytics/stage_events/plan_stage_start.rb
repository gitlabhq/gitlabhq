# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class PlanStageStart < MetricsBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue first associated with a milestone or first added to a board")
          end

          def self.identifier
            :plan_stage_start
          end

          def object_type
            Issue
          end

          def column_list
            [
              issue_metrics_table[:first_associated_with_milestone_at],
              issue_metrics_table[:first_added_to_board_at]
            ]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            super
              .where(issue_metrics_table[:first_added_to_board_at].not_eq(nil).or(issue_metrics_table[:first_associated_with_milestone_at].not_eq(nil)))
              .where(issue_metrics_table[:first_mentioned_in_commit_at].not_eq(nil))
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
