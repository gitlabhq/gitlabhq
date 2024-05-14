# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        # Usage example
        #
        # In metric YAML definition:
        #
        # instrumentation_class: AggregatedMetric
        # data_source: redis_hll
        # options:
        #   aggregate:
        #     attribute: user.id
        #   events:
        #     - 'incident_management_alert_status_changed'
        #     - 'incident_management_alert_assigned'
        #     - 'incident_management_alert_todo'
        #     - 'incident_management_alert_create_incident'

        class AggregatedMetric < BaseMetric
          FALLBACK = -1

          def initialize(metric_definition)
            super
            @source = metric_definition[:data_source]
            @aggregate = options.fetch(:aggregate, {})
          end

          def value
            alt_usage_data(fallback: FALLBACK) do
              Aggregates::Aggregate
                .new(Time.current)
                .calculate_count_for_aggregation(
                  aggregation: aggregate_config,
                  time_frame: time_frame
                )
            end
          end

          private

          attr_accessor :source, :aggregate

          def aggregate_config
            {
              source: source,
              events: options[:events],
              attribute: aggregate[:attribute]
            }
          end
        end
      end
    end
  end
end
