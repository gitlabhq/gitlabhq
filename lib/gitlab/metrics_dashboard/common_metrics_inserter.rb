# frozen_string_literal: true

module Gitlab
  module MetricsDashboard
    class CommonMetricsInserter
      class << self
        # For each metric in the dashboard config, attempts to find a corresponding
        # database record. If found, includes the record's id in the dashboard config.
        def transform!(dashboard, _project)
          common_metrics = ::PrometheusMetric.common

          for_metrics(dashboard) do |metric|
            metric_record = common_metrics.find { |m| m.identifier == metric[:id] }
            metric[:metric_id] = metric_record.id if metric_record
          end
        end

        private

        def for_metrics(dashboard)
          dashboard[:panel_groups].each do |panel_group|
            panel_group[:panels].each do |panel|
              panel[:metrics].each do |metric|
                yield metric
              end
            end
          end
        end
      end
    end
  end
end
