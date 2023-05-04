# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersProjectTypeActiveOnlineMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.project_type.active.online }
        end
      end
    end
  end
end
