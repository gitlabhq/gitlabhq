# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestFirstDeployedToProduction < MetricsBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request first deployed to production")
          end

          def self.identifier
            :merge_request_first_deployed_to_production
          end

          def object_type
            MergeRequest
          end

          def column_list
            [mr_metrics_table[:first_deployed_to_production_at]]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            super.where(timestamp_projection.gteq(mr_table[:created_at]))
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
