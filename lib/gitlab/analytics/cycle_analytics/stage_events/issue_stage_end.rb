# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueStageEnd < MetricsBasedStageEvent
          def self.name
            PlanStageStart.name
          end

          def self.identifier
            :issue_stage_end
          end

          def object_type
            Issue
          end

          def timestamp_projection
            Arel::Nodes::NamedFunction.new('COALESCE', [
              issue_metrics_table[:first_associated_with_milestone_at],
              issue_metrics_table[:first_added_to_board_at]
            ])
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            super.where(issue_metrics_table[:first_added_to_board_at].not_eq(nil).or(issue_metrics_table[:first_associated_with_milestone_at].not_eq(nil)))
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
