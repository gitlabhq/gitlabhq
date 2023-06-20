# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountAllCiBuildsMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Build }
        end
      end
    end
  end
end
