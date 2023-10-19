# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsMetric < DatabaseMetric
          operation :count

          start { Project.minimum(:id) }
          finish { Project.maximum(:id) }

          relation { Project }
        end
      end
    end
  end
end
