# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: TotalCountMetric
        # options:
        #   event: commit_pushed
        #
        class TotalCountMetric < BaseMetric
          include Gitlab::UsageDataCounters::RedisCounter

          KEY_PREFIX = "{event_counters}_"

          def self.redis_key(event_name)
            KEY_PREFIX + event_name
          end

          def value
            events.sum do |event|
              redis_usage_data do
                total_count(self.class.redis_key(event[:name]))
              end
            end
          end
        end
      end
    end
  end
end
