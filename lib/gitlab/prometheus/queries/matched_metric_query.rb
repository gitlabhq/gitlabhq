module Gitlab
  module Prometheus
    module Queries
      class MatchedMetricQuery < BaseQuery
        MAX_QUERY_ITEMS = 40.freeze

        def query
          groups_data.map do |group, data|
            {
              group: group.name,
              priority: group.priority,
              active_metrics: data[:active_metrics],
              metrics_missing_requirements: data[:metrics_missing_requirements]
            }
          end
        end

        private

        def groups_data
          metrics_groups = groups_with_active_metrics(Gitlab::Prometheus::MetricGroup.common_metrics)
          lookup = active_series_lookup(metrics_groups)

          groups = {}

          metrics_groups.each do |group|
            groups[group] ||= { active_metrics: 0, metrics_missing_requirements: 0 }
            active_metrics = group.metrics.count { |metric| metric.required_metrics.all?(&lookup.method(:has_key?)) }

            groups[group][:active_metrics] += active_metrics
            groups[group][:metrics_missing_requirements] += group.metrics.count - active_metrics
          end

          groups
        end

        def active_series_lookup(metric_groups)
          timeframe_start = 8.hours.ago
          timeframe_end = Time.now

          series = metric_groups.flat_map(&:metrics).flat_map(&:required_metrics).uniq

          lookup = series.each_slice(MAX_QUERY_ITEMS).flat_map do |batched_series|
            client_series(*batched_series, start: timeframe_start, stop: timeframe_end)
              .select(&method(:has_matching_label?))
              .map { |series_info| [series_info['__name__'], true] }
          end
          lookup.to_h
        end

        def has_matching_label?(series_info)
          series_info.key?('environment')
        end

        def available_metrics
          @available_metrics ||= client_label_values || []
        end

        def filter_active_metrics(metric_group)
          metric_group.metrics.select! do |metric|
            metric.required_metrics.all?(&available_metrics.method(:include?))
          end
          metric_group
        end

        def groups_with_active_metrics(metric_groups)
          metric_groups.map(&method(:filter_active_metrics)).select { |group| group.metrics.any? }
        end

        def metrics_with_required_series(metric_groups)
          metric_groups.flat_map do |group|
            group.metrics.select do |metric|
              metric.required_metrics.all?(&available_metrics.method(:include?))
            end
          end
        end
      end
    end
  end
end
