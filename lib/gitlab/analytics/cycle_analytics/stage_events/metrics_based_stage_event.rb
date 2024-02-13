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

          # rubocop: disable CodeReuse/ActiveRecord
          def apply_negated_query_customization(query)
            super.joins(:metrics)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def column_list
            [timestamp_projection]
          end

          def include_in(query, **)
            super.left_joins(:metrics)
          end
        end
      end
    end
  end
end
