# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraImportsFinishedProjectsMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::JiraImportState.finished }
        end
      end
    end
  end
end
