# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUserAuthMetric < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation do
            AuthenticationEvent.success
          end
        end
      end
    end
  end
end
