# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCsvImportsMetric < DatabaseMetric
          operation :count

          relation { ::Issues::CsvImport }
        end
      end
    end
  end
end
