# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestMerged < MetricsBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request merged")
          end

          def self.identifier
            :merge_request_merged
          end

          def object_type
            MergeRequest
          end

          def column_list
            [mr_metrics_table[:merged_at]]
          end
        end
      end
    end
  end
end
