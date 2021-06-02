# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        UNION_OF_AGGREGATED_METRICS = 'OR'
        INTERSECTION_OF_AGGREGATED_METRICS = 'AND'
        ALLOWED_METRICS_AGGREGATIONS = [UNION_OF_AGGREGATED_METRICS, INTERSECTION_OF_AGGREGATED_METRICS].freeze
        AGGREGATED_METRICS_PATH = Rails.root.join('config/metrics/aggregates/*.yml')
        AggregatedMetricError = Class.new(StandardError)
        UnknownAggregationOperator = Class.new(AggregatedMetricError)
        UnknownAggregationSource = Class.new(AggregatedMetricError)
        DisallowedAggregationTimeFrame = Class.new(AggregatedMetricError)

        DATABASE_SOURCE = 'database'
        REDIS_SOURCE = 'redis'

        SOURCES = {
          DATABASE_SOURCE => Sources::PostgresHll,
          REDIS_SOURCE => Sources::RedisHll
        }.freeze

        class Aggregate
          include Gitlab::Usage::TimeFrame

          def initialize(recorded_at)
            @aggregated_metrics = load_metrics(AGGREGATED_METRICS_PATH)
            @recorded_at = recorded_at
          end

          def all_time_data
            aggregated_metrics_data(start_date: nil, end_date: nil, time_frame: Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME)
          end

          def monthly_data
            aggregated_metrics_data(**monthly_time_range.merge(time_frame: Gitlab::Usage::TimeFrame::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME))
          end

          def weekly_data
            aggregated_metrics_data(**weekly_time_range.merge(time_frame: Gitlab::Usage::TimeFrame::SEVEN_DAYS_TIME_FRAME_NAME))
          end

          private

          attr_accessor :aggregated_metrics, :recorded_at

          def aggregated_metrics_data(start_date:, end_date:, time_frame:)
            aggregated_metrics.each_with_object({}) do |aggregation, data|
              next if aggregation[:feature_flag] && Feature.disabled?(aggregation[:feature_flag], default_enabled: :yaml, type: :development)
              next unless aggregation[:time_frame].include?(time_frame)

              case aggregation[:source]
              when REDIS_SOURCE
                if time_frame == Gitlab::Usage::TimeFrame::ALL_TIME_TIME_FRAME_NAME
                  data[aggregation[:name]] = Gitlab::Utils::UsageData::FALLBACK
                  Gitlab::ErrorTracking
                    .track_and_raise_for_dev_exception(
                      DisallowedAggregationTimeFrame.new("Aggregation time frame: 'all' is not allowed for aggregation with source: '#{REDIS_SOURCE}'")
                    )
                else
                  data[aggregation[:name]] = calculate_count_for_aggregation(aggregation: aggregation, start_date: start_date, end_date: end_date)
                end
              when DATABASE_SOURCE
                data[aggregation[:name]] = calculate_count_for_aggregation(aggregation: aggregation, start_date: start_date, end_date: end_date)
              else
                Gitlab::ErrorTracking
                  .track_and_raise_for_dev_exception(UnknownAggregationSource.new("Aggregation source: '#{aggregation[:source]}' must be included in #{SOURCES.keys}"))

                data[aggregation[:name]] = Gitlab::Utils::UsageData::FALLBACK
              end
            end
          end

          def calculate_count_for_aggregation(aggregation:, start_date:, end_date:)
            source = SOURCES[aggregation[:source]]

            case aggregation[:operator]
            when UNION_OF_AGGREGATED_METRICS
              source.calculate_metrics_union(metric_names: aggregation[:events], start_date: start_date, end_date: end_date, recorded_at: recorded_at)
            when INTERSECTION_OF_AGGREGATED_METRICS
              source.calculate_metrics_intersections(metric_names: aggregation[:events], start_date: start_date, end_date: end_date, recorded_at: recorded_at)
            else
              Gitlab::ErrorTracking
                .track_and_raise_for_dev_exception(UnknownAggregationOperator.new("Events should be aggregated with one of operators #{ALLOWED_METRICS_AGGREGATIONS}"))
              Gitlab::Utils::UsageData::FALLBACK
            end
          rescue Gitlab::UsageDataCounters::HLLRedisCounter::EventError, AggregatedMetricError => error
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
        end
      end
    end
  end
end

Gitlab::Usage::Metrics::Aggregates::Aggregate.prepend_mod_with('Gitlab::Usage::Metrics::Aggregates::Aggregate')
