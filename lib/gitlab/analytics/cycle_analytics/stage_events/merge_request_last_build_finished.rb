# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestLastBuildFinished < MetricsBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request last build finish time")
          end

          def self.identifier
            :merge_request_last_build_finished
          end

          def object_type
            MergeRequest
          end

          def timestamp_projection
            mr_metrics_table[:latest_build_finished_at]
          end
        end
      end
    end
  end
end
