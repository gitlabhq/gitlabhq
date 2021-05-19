# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class CodeStageStart < StageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue first mentioned in a commit")
          end

          def self.identifier
            :code_stage_start
          end

          def object_type
            MergeRequest
          end

          def column_list
            [
              issue_metrics_table[:first_mentioned_in_commit_at],
              mr_metrics_table[:first_commit_at]
            ]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query
              .joins(merge_requests_closing_issues_join)
              .joins(issue_metrics_join)
              .joins(mr_metrics_join)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def issue_metrics_join
            mr_closing_issues_table
              .join(issue_metrics_table, Arel::Nodes::OuterJoin)
              .on(mr_closing_issues_table[:issue_id].eq(issue_metrics_table[:issue_id]))
              .join_sources
          end

          def merge_requests_closing_issues_join
            mr_table
              .join(mr_closing_issues_table, Arel::Nodes::OuterJoin)
              .on(mr_table[:id].eq(mr_closing_issues_table[:merge_request_id]))
              .join_sources
          end

          def mr_metrics_join
            mr_metrics_table
              .join(mr_metrics_table, Arel::Nodes::OuterJoin)
              .on(mr_metrics_table[:merge_request_id].eq(mr_table[:id]))
              .join_sources
          end
        end
      end
    end
  end
end
