# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraImportsUsersMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            ::JiraImportState
          end
        end
      end
    end
  end
end
