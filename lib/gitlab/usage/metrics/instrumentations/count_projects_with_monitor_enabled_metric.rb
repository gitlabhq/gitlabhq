# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithMonitorEnabledMetric < DatabaseMetric
          operation :count

          metric_options do
            {
              batch_size: 10_000
            }
          end

          relation { ProjectFeature.where.not(monitor_access_level: ProjectFeature::DISABLED) }
        end
      end
    end
  end
end
