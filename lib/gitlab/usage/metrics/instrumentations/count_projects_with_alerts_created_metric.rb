# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithAlertsCreatedMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation do
            ::AlertManagement::Alert
          end
        end
      end
    end
  end
end
