# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountFooMetric < DatabaseMetric
          operation :count

          relation do
            # Insert ActiveRecord relation here
          end
        end
      end
    end
  end
end
