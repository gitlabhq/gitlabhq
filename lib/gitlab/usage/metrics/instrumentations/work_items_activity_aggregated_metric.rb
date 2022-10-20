# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class WorkItemsActivityAggregatedMetric < AggregatedMetric
          available? { Feature.enabled?(:track_work_items_activity) }
        end
      end
    end
  end
end
