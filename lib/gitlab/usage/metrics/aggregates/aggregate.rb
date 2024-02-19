# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        class Aggregate
          include Gitlab::Usage::TimeFrame

          def initialize(recorded_at)
            @recorded_at = recorded_at
          end

          def calculate_count_for_aggregation(aggregation:, time_frame:)
            with_validate_configuration(aggregation, time_frame) do
              source = SOURCES[aggregation[:source]]
              events = select_defined_events(aggregation[:events], aggregation[:source])
              property_name = aggregation[:attribute]

              source.calculate_metrics_union(**time_constraints(time_frame)
                .merge(metric_names: events, property_name: property_name, recorded_at: recorded_at))
            end
          rescue Gitlab::UsageDataCounters::HLLRedisCounter::EventError, AggregatedMetricError => error
            failure(error)
          end

          private

          attr_accessor :recorded_at

          def with_validate_configuration(aggregation, time_frame)
            source = aggregation[:source]

            unless SOURCES[source]
              return failure(
                UnknownAggregationSource
                  .new("Aggregation source: '#{source}' must be included in #{SOURCES.keys}")
              )
            end

            if time_frame == Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME && source == REDIS_SOURCE
              return failure(
                DisallowedAggregationTimeFrame
                  .new("Aggregation time frame: 'all' is not allowed for aggregation with source: '#{REDIS_SOURCE}'")
              )
            end

            yield
          end

          def failure(error)
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
            Gitlab::Utils::UsageData::FALLBACK
          end

          def time_constraints(time_frame)
            case time_frame
            when Gitlab::Usage::TimeFrame::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME
              monthly_time_range
            when Gitlab::Usage::TimeFrame::SEVEN_DAYS_TIME_FRAME_NAME
              weekly_time_range
            when Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME
              { start_date: nil, end_date: nil }
            end
          end

          def select_defined_events(events, source)
            # Database source metrics get validated inside the PostgresHll class:
            # https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage/metrics/aggregates/sources/postgres_hll.rb#L16
            return events if source != ::Gitlab::Usage::Metrics::Aggregates::REDIS_SOURCE

            events.select do |event|
              ::Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(event)
            end
          end
        end
      end
    end
  end
end

Gitlab::Usage::Metrics::Aggregates::Aggregate.prepend_mod
