# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UniqueCountMetric < BaseMetric
          def value
            keys = metric_definition.event_selection_rules.flat_map { |e| e.redis_keys_for_time_frame(time_frame) }

            redis_usage_data do
              Gitlab::Redis::HLL.count(keys: keys.uniq)
            end
          end
        end
      end
    end
  end
end
