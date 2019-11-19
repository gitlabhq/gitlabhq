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

          def timestamp_projection
            issue_metrics_table[:first_mentioned_in_commit_at]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            issue_metrics_join = mr_closing_issues_table
              .join(issue_metrics_table)
              .on(mr_closing_issues_table[:issue_id].eq(issue_metrics_table[:issue_id]))
              .join_sources

            query.joins(:merge_requests_closing_issues).joins(issue_metrics_join)
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
