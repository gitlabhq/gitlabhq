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
        #     operator: OR
        #     attribute: user_id
        #   events:
        #     - 'incident_management_alert_status_changed'
        #     - 'incident_management_alert_assigned'
        #     - 'incident_management_alert_todo'
        #     - 'incident_management_alert_create_incident'

        class AggregatedMetric < BaseMetric
          FALLBACK = -1

          def initialize(metric_definition)
            super
            @source = parse_data_source_to_legacy_value(metric_definition)
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

          def suggested_name
            Gitlab::Usage::Metrics::NameSuggestion.for(:alt)
          end

          private

          attr_accessor :source, :aggregate

          # TODO: This method is a temporary measure that
          # handles backwards compatibility until
          # point 5 from is resolved https://gitlab.com/gitlab-org/gitlab/-/issues/370963#implementation
          def parse_data_source_to_legacy_value(metric_definition)
            return 'redis' if metric_definition[:data_source] == 'redis_hll'

            metric_definition[:data_source]
          end

          def aggregate_config
            {
              source: source,
              events: options[:events],
              operator: aggregate[:operator]
            }
          end
        end
      end
    end
  end
end
