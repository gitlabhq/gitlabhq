# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestLastBuildFinished < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request last build finish time")
          end

          def self.identifier
            :merge_request_last_build_finished
          end

          def object_type
            MergeRequest
          end
        end
      end
    end
  end
end
