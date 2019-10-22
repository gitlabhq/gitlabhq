# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestMerged < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request merged")
          end

          def self.identifier
            :merge_request_merged
          end

          def object_type
            MergeRequest
          end

          def timestamp_projection
            mr_metrics_table[:merged_at]
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
