# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersProjectTypeActiveMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.project_type.active }
        end
      end
    end
  end
end
