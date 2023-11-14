# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UniqueUsersAllImportsMetric < NumbersMetric
          IMPORTS_METRICS = [
            ProjectImportsCreatorsMetric,
            BulkImportsUsersMetric,
            JiraImportsUsersMetric,
            CsvImportsUsersMetric,
            GroupImportsUsersMetric
          ].freeze

          operation :add

          data do |time_frame|
            IMPORTS_METRICS.map { |metric| metric.new(time_frame: time_frame).value }
          end

          # overwriting instrumentation to generate the appropriate sql query
          def instrumentation
            metric_queries = IMPORTS_METRICS.map do |metric|
              "(#{metric.new(time_frame: time_frame).instrumentation})"
            end.join(' + ')

            "SELECT #{metric_queries}"
          end
        end
      end
    end
  end
end
