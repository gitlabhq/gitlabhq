# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountJiraImportsMetric < DatabaseMetric
          operation :count

          relation { JiraImportState }
        end
      end
    end
  end
end
