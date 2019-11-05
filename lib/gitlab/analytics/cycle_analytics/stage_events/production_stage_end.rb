# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class ProductionStageEnd < StageEvent
          def self.name
            PlanStageStart.name
          end

          def self.identifier
            :production_stage_end
          end

          def object_type
            Issue
          end

          def timestamp_projection
            mr_metrics_table[:first_deployed_to_production_at]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query.joins(merge_requests_closing_issues: { merge_request: [:metrics] }).where(mr_metrics_table[:first_deployed_to_production_at].gteq(mr_table[:created_at]))
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
