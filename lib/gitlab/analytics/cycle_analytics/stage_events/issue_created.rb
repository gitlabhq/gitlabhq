# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueCreated < StageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue created")
          end

          def self.identifier
            :issue_created
          end

          def object_type
            Issue
          end

          def column_list
            [issue_table[:created_at]]
          end
        end
      end
    end
  end
end
