# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        class Aggregate
          include Gitlab::Usage::TimeFrame

          def initialize(recorded_at)
            @aggregated_metrics = load_metrics(AGGREGATED_METRICS_PATH)
            @recorded_at = recorded_at
          end

          def all_time_data
            aggregated_metrics_data(Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME)
          end

          def monthly_data
            aggregated_metrics_data(Gitlab::Usage::TimeFrame::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME)
          end

          def weekly_data
            aggregated_metrics_data(Gitlab::Usage::TimeFrame::SEVEN_DAYS_TIME_FRAME_NAME)
          end

          private

          attr_accessor :aggregated_metrics, :recorded_at

          def aggregated_metrics_data(time_frame)
            aggregated_metrics.each_with_object({}) do |aggregation, data|
              next if aggregation[:feature_flag] && Feature.disabled?(aggregation[:feature_flag], type: :development)
              next unless aggregation[:time_frame].include?(time_frame)

              data[aggregation[:name]] = calculate_count_for_aggregation(aggregation: aggregation, time_frame: time_frame)
            end
          end

          def calculate_count_for_aggregation(aggregation:, time_frame:)
            with_validate_configuration(aggregation, time_frame) do
              source = SOURCES[aggregation[:source]]

              if aggregation[:operator] == UNION_OF_AGGREGATED_METRICS
                source.calculate_metrics_union(**time_constraints(time_frame).merge(metric_names: aggregation[:events], recorded_at: recorded_at))
              else
                source.calculate_metrics_intersections(**time_constraints(time_frame).merge(metric_names: aggregation[:events], recorded_at: recorded_at))
              end
            end
          rescue Gitlab::UsageDataCounters::HLLRedisCounter::EventError, AggregatedMetricError => error
            failure(error)
          end

          def with_validate_configuration(aggregation, time_frame)
            source = aggregation[:source]

            unless ALLOWED_METRICS_AGGREGATIONS.include?(aggregation[:operator])
              return failure(
                UnknownAggregationOperator
                  .new("Events should be aggregated with one of operators #{ALLOWED_METRICS_AGGREGATIONS}")
              )
            end

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

          def load_metrics(wildcard)
            Dir[wildcard].each_with_object([]) do |path, metrics|
              metrics.push(*load_yaml_from_path(path))
            end
          end

          def load_yaml_from_path(path)
            YAML.safe_load(File.read(path), aliases: true)&.map(&:with_indifferent_access)
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
        end
      end
    end
  end
end

Gitlab::Usage::Metrics::Aggregates::Aggregate.prepend_mod_with('Gitlab::Usage::Metrics::Aggregates::Aggregate')
