# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersGroupTypeActiveMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.group_type.active }
        end
      end
    end
  end
end
