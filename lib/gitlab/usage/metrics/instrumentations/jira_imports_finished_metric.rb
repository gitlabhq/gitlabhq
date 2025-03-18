# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraImportsFinishedMetric < DatabaseMetric
          operation :count

          relation { ::JiraImportState.finished }
        end
      end
    end
  end
end
