# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class PlanStageStart < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue first associated with a milestone or issue first added to a board")
          end

          def self.identifier
            :plan_stage_start
          end

          def object_type
            Issue
          end
        end
      end
    end
  end
end
