# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Aggregates
        module Sources
          module Calculations
            module Intersection
              def calculate_metrics_intersections(metric_names:, start_date:, end_date:, recorded_at:, subset_powers_cache: Hash.new({}))
                # calculate power of intersection of all given metrics from inclusion exclusion principle
                # |A + B + C| = (|A| + |B| + |C|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C|)  =>
                # |A & B & C| = - (|A| + |B| + |C|) + (|A & B| + |A & C| + .. + |C & D|) + |A + B + C|
                # |A + B + C + D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A & B & C & D| =>
                # |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) - |A + B + C + D|

                # calculate each components of equation except for the last one |A & B & C & D| = (|A| + |B| + |C| + |D|) - (|A & B| + |A & C| + .. + |C & D|) + (|A & B & C| + |B & C & D|) -  ...
                subset_powers_data = subsets_intersection_powers(metric_names, start_date, end_date, recorded_at, subset_powers_cache)

                # calculate last component of the equation  |A & B & C & D| = .... - |A + B + C + D|
                power_of_union_of_all_metrics = begin
                  subset_powers_cache[metric_names.size][metric_names.join('_+_')] ||= \
                    calculate_metrics_union(metric_names: metric_names, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
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

              private

              def subsets_intersection_powers(metric_names, start_date, end_date, recorded_at, subset_powers_cache)
                subset_sizes = (1...metric_names.size)

                subset_sizes.map do |subset_size|
                  if subset_size > 1
                    # calculate sum of powers of intersection between each subset (with given size) of metrics:  #|A + B + C + D| = ... - (|A & B| + |A & C| + .. + |C & D|)
                    metric_names.combination(subset_size).sum do |metrics_subset|
                      subset_powers_cache[subset_size][metrics_subset.join('_&_')] ||=
                        calculate_metrics_intersections(metric_names: metrics_subset, start_date: start_date, end_date: end_date, recorded_at: recorded_at, subset_powers_cache: subset_powers_cache)
                    end
                  else
                    # calculate sum of powers of each set (metric) alone  #|A + B + C + D| = (|A| + |B| + |C| + |D|) - ...
                    metric_names.sum do |metric|
                      subset_powers_cache[subset_size][metric] ||= \
                        calculate_metrics_union(metric_names: metric, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
                    end
                  end
                end
              end

              def sum_subset_powers(subset_powers_data, subset_powers_size_even)
                sum_without_sign = subset_powers_data.to_enum.with_index.sum do |value, index|
                  (index + 1).odd? ? value : -value
                end

                (subset_powers_size_even ? -1 : 1) * sum_without_sign
              end
            end
          end
        end
      end
    end
  end
end
