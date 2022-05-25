# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraImportsTotalImportedIssuesCountMetric < DatabaseMetric
          operation :sum, column: :imported_issues_count

          relation { JiraImportState.finished }
        end
      end
    end
  end
end
