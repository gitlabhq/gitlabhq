# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountTopLevelGroupsMetric < DatabaseMetric
          operation :count, column: :id

          relation { Group.top_level }
        end
      end
    end
  end
end
