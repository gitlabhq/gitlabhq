# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BulkImportsUsersMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            ::BulkImport
          end
        end
      end
    end
  end
end
