# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnerManagerCustomExecutorsMetric < DatabaseMetric
          operation :count

          relation do
            ::Ci::RunnerManager.custom_executor_type
          end
        end
      end
    end
  end
end
