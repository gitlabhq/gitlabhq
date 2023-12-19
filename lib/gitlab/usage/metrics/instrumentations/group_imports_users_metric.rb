# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GroupImportsUsersMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            ::GroupImportState
          end
        end
      end
    end
  end
end
