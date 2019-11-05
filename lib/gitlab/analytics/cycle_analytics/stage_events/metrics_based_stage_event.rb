# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MetricsBasedStageEvent < StageEvent
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
