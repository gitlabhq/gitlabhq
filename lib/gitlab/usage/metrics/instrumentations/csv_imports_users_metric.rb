# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CsvImportsUsersMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            ::Issues::CsvImport
          end
        end
      end
    end
  end
end
