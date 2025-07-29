# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersOnlineMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.online }
        end
      end
    end
  end
end
