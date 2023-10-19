# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountPackagesMetric < DatabaseMetric
          operation :count

          relation { ::Packages::Package }
        end
      end
    end
  end
end
