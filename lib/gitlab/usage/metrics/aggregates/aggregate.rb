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
          delegate :weekly_time_range,
                   :monthly_time_range,
                   to: Gitlab::UsageDataCounters::HLLRedisCounter

          def initialize(recorded_at)
            @aggregated_metrics = load_metrics(AGGREGATED_METRICS_PATH)
            @recorded_at = recorded_at
          end

          def all_time_data
            aggregated_metrics_data(start_date: nil, end_date: nil, time_frame: Gitlab::Utils::UsageData::ALL_TIME_TIME_FRAME_NAME)
          end

          def monthly_data
            aggregated_metrics_data(**monthly_time_range.merge(time_frame: Gitlab::Utils::UsageData::TWENTY_EIGHT_DAYS_TIME_FRAME_NAME))
          end

          def weekly_data
            aggregated_metrics_data(**weekly_time_range.merge(time_frame: Gitlab::Utils::UsageData::SEVEN_DAYS_TIME_FRAME_NAME))
          end

          private

          attr_accessor :aggregated_metrics, :recorded_at

          def aggregated_metrics_data(start_date:, end_date:, time_frame:)
            aggregated_metrics.each_with_object({}) do |aggregation, data|
              next if aggregation[:feature_flag] && Feature.disabled?(aggregation[:feature_flag], default_enabled: :yaml, type: :development)
              next unless aggregation[:time_frame].include?(time_frame)

              case aggregation[:source]
              when REDIS_SOURCE
                if time_frame == Gitlab::Utils::UsageData::ALL_TIME_TIME_FRAME_NAME
                  data[aggregation[:name]] = Gitlab::Utils::UsageData::FALLBACK
                  Gitlab::ErrorTracking
                    .track_and_raise_for_dev_exception(
                      DisallowedAggregationTimeFrame.new("Aggregation time frame: 'all' is not allowed for aggregation with source: '#{REDIS_SOURCE}'")
                    )
                else
                  data[aggregation[:name]] = calculate_count_for_aggregation(aggregation: aggregation, start_date: start_date, end_date: end_date)
                end
              when DATABASE_SOURCE
                next unless Feature.enabled?('database_sourced_aggregated_metrics', default_enabled: false, type: :development)

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
              calculate_metrics_intersections(source: source, metric_names: aggregation[:events], start_date: start_date, end_date: end_date)
            else
              Gitlab::ErrorTracking
                .track_and_raise_for_dev_exception(UnknownAggregationOperator.new("Events should be aggregated with one of operators #{ALLOWED_METRICS_AGGREGATIONS}"))
              Gitlab::Utils::UsageData::FALLBACK
            end
          rescue Gitlab::UsageDataCounters::HLLRedisCounter::EventError, AggregatedMetricError => error
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
            Gitlab::Utils::UsageData::FALLBACK
          end

          # calculate intersection of 'n' sets based on inclusion exclusion principle https://en.wikipedia.org/wiki/Inclusion%E2%80%93exclusion_principle
          # this method will be extracted to dedicated module with https://gitlab.com/gitlab-org/gitlab/-/issues/273391
          def calculate_metrics_intersections(source:, metric_names:, start_date:, end_date:, subset_powers_cache: Hash.new({}))
            # calculate power of intersection of all given metrics from inclusion exclusion principle
            # |A + B + C| = (|A| + |B| + |C|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C|)  =>
            # |A & B & C| = - (|A| + |B| + |C|) + (|A & B| + |A & C| + .. + |C & D|) + |A + B + C|
            # |A + B + C + D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A & B & C & D| =>
            # |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A + B + C + D|

            # calculate each components of equation except for the last one |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) -  ...
            subset_powers_data = subsets_intersection_powers(source, metric_names, start_date, end_date, subset_powers_cache)

            # calculate last component of the equation  |A & B & C & D| = .... - |A + B + C + D|
            power_of_union_of_all_metrics = begin
              subset_powers_cache[metric_names.size][metric_names.join('_+_')] ||= \
                source.calculate_metrics_union(metric_names: metric_names, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
            end

            # in order to determine if part of equation (|A & B & C|, |A & B & C & D|), that represents the intersection that we need to calculate,
            # is positive or negative in particular equation we need to determine if number of subsets is even or odd. Please take a look at two examples below
            # |A + B + C| = (|A| + |B| + |C|) - (|A & B| + |A & C| + .. + |C & D|) + |A & B & C|  =>
            # |A & B & C| = - (|A| + |B| + |C|) + (|A & B| + |A & C| + .. + |C & D|) + |A + B + C|
            # |A + B + C + D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A & B & C & D| =>
            # |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A + B + C + D|
            subset_powers_size_even = subset_powers_data.size.even?

            # sum all components of equation except for the last one |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) -  ... =>
            sum_of_all_subset_powers = sum_subset_powers(subset_powers_data, subset_powers_size_even)

            # add last component of the equation |A & B & C & D| = sum_of_all_subset_powers - |A + B + C + D|
            sum_of_all_subset_powers + (subset_powers_size_even ? power_of_union_of_all_metrics : -power_of_union_of_all_metrics)
          end

          def sum_subset_powers(subset_powers_data, subset_powers_size_even)
            sum_without_sign =  subset_powers_data.to_enum.with_index.sum do |value, index|
              (index + 1).odd? ? value : -value
            end

            (subset_powers_size_even ? -1 : 1) * sum_without_sign
          end

          def subsets_intersection_powers(source, metric_names, start_date, end_date, subset_powers_cache)
            subset_sizes = (1...metric_names.size)

            subset_sizes.map do |subset_size|
              if subset_size > 1
                # calculate sum of powers of intersection between each subset (with given size) of metrics:  #|A + B + C + D| = ... - (|A & B| + |A & C| + .. + |C & D|)
                metric_names.combination(subset_size).sum do |metrics_subset|
                  subset_powers_cache[subset_size][metrics_subset.join('_&_')] ||=
                    calculate_metrics_intersections(source: source, metric_names: metrics_subset, start_date: start_date, end_date: end_date, subset_powers_cache: subset_powers_cache)
                end
              else
                # calculate sum of powers of each set (metric) alone  #|A + B + C + D| = (|A| + |B| + |C| + |D|) - ...
                metric_names.sum do |metric|
                  subset_powers_cache[subset_size][metric] ||= \
                    source.calculate_metrics_union(metric_names: metric, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
                end
              end
            end
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

Gitlab::Usage::Metrics::Aggregates::Aggregate.prepend_if_ee('EE::Gitlab::Usage::Metrics::Aggregates::Aggregate')
