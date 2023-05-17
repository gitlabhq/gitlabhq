# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner }
        end
      end
    end
  end
end
