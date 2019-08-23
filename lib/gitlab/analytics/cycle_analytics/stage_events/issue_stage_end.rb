# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueStageEnd < SimpleStageEvent
          def self.name
            PlanStageStart.name
          end

          def self.identifier
            :issue_stage_end
          end

          def object_type
            Issue
          end
        end
      end
    end
  end
end
