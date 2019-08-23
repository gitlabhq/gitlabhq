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
        end
      end
    end
  end
end
