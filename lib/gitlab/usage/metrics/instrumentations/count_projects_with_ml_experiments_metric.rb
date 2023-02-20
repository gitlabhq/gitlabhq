# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithMlExperimentsMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { Ml::Experiment }
        end
      end
    end
  end
end
