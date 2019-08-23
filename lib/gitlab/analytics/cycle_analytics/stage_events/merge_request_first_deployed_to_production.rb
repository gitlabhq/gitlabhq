# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestFirstDeployedToProduction < SimpleStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request first deployed to production")
          end

          def self.identifier
            :merge_request_first_deployed_to_production
          end

          def object_type
            MergeRequest
          end
        end
      end
    end
  end
end
