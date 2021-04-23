# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestCreated < StageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge request created")
          end

          def self.identifier
            :merge_request_created
          end

          def object_type
            MergeRequest
          end

          def column_list
            [mr_table[:created_at]]
          end
        end
      end
    end
  end
end
