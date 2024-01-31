# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueDeployedToProduction < StageEvent
          def self.name
            _("Issue first deployed to production")
          end

          def self.identifier
            :issue_deployed_to_production
          end

          def object_type
            Issue
          end

          def column_list
            [mr_metrics_table[:first_deployed_to_production_at]]
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_query_customization(query)
            query.joins(merge_requests_closing_issues: { merge_request: [:metrics] }).where(mr_metrics_table[:first_deployed_to_production_at].gteq(mr_table[:created_at]))
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def include_in(query, **)
            query.left_joins(merge_requests_closing_issues: { merge_request: [:metrics] })
          end
        end
      end
    end
  end
end
