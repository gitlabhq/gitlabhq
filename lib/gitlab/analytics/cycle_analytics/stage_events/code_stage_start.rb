# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class CodeStageStart < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue first mentioned in a commit")
          end

          def self.identifier
            :code_stage_start
          end

          def object_type
            MergeRequest
          end
        end
      end
    end
  end
end
