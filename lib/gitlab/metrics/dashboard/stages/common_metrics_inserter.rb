# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class CommonMetricsInserter < BaseStage
          # For each metric in the dashboard config, attempts to
          # find a corresponding database record. If found,
          # includes the record's id in the dashboard config.
          def transform!
            common_metrics = ::PrometheusMetricsFinder.new(common: true).execute

            for_metrics do |metric|
              metric_record = common_metrics.find { |m| m.identifier == metric[:id] }
              metric[:metric_id] = metric_record.id if metric_record
            end
          end
        end
      end
    end
  end
end
