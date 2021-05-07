# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountBoardsMetric < DatabaseMetric
          operation :count

          relation { Board }
        end
      end
    end
  end
end
