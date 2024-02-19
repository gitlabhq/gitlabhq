# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        module Sources
          class RedisHll
            def self.calculate_metrics_union(metric_names:, start_date:, end_date:, property_name:, recorded_at: nil)
              union = Gitlab::UsageDataCounters::HLLRedisCounter.calculate_events_union(
                event_names: metric_names,
                property_name: property_name,
                start_date: start_date,
                end_date: end_date
              )

              return union if union >= 0

              raise UnionNotAvailable, "Union data not available for #{metric_names}"
            end
          end
        end
      end
    end
  end
end
