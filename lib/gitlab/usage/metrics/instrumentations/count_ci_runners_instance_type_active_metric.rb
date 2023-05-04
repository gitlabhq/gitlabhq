# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersInstanceTypeActiveMetric < DatabaseMetric
          operation :count

          relation do
            ::Ci::Runner.instance_type.active
          end
        end
      end
    end
  end
end
