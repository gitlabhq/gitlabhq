module Gitlab::Prometheus::Queries
  class MatchedMetricsQuery < BaseQuery
    MAX_QUERY_ITEMS = 40.freeze

    def self.metrics
      @metrics ||= YAML.load_file(Rails.root.join('config/additional_metrics.yml')).map(&:deep_symbolize_keys)
    end

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

    def groups_data
      metrics_series = metrics_with_series(Gitlab::Prometheus::MetricGroup.all)
      lookup = active_series_lookup(metrics_series)

      groups = {}

      metrics_series.each do |metrics, series|
        groups[metrics.group] ||= { active_metrics: 0, metrics_missing_requirements: 0 }
        group = groups[metrics.group]

        if series.all?(&lookup.method(:has_key?))
          group[:active_metrics] += 1
        else
          group[:metrics_missing_requirements] += 1
        end
        group
      end

      groups
    end

    def active_series_lookup(metrics)
      timeframe_start = 8.hours.ago
      timeframe_end = Time.now

      series = metrics.flat_map { |metrics, series| series }.uniq

      lookup = series.each_slice(MAX_QUERY_ITEMS).flat_map do |batched_series|
        client_series(*batched_series, start: timeframe_start, stop: timeframe_end)
          .select(&method(:has_matching_label))
          .map { |series_info| [series_info['__name__'], true] }
      end
      lookup.to_h
    end

    def has_matching_label(series_info)
      series_info.has_key?('environment')
    end

    def metrics_with_series(metric_groups)
      label_values = client_label_values || []

      metrics = metric_groups.flat_map do |group|
        group.metrics.map do |metric|
          matcher = Regexp.compile(metric.detect)
          [metric, label_values.select(&matcher.method(:match))]
        end
      end

      metrics.select { |metric, labels| labels&.any? }
    end
  end
end
