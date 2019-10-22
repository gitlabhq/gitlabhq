# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueFirstMentionedInCommit < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue first mentioned in a commit")
          end

          def self.identifier
            :issue_first_mentioned_in_commit
          end

          def object_type
            Issue
          end

          def timestamp_projection
            issue_metrics_table[:first_mentioned_in_commit_at]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query.joins(:metrics)
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
