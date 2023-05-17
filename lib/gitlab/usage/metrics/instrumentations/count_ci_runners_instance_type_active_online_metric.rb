# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersInstanceTypeActiveOnlineMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.instance_type.active.online }
        end
      end
    end
  end
end
