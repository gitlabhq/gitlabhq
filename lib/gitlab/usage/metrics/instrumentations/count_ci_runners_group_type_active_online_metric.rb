# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiRunnersGroupTypeActiveOnlineMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Runner.group_type.active.online }
        end
      end
    end
  end
end
