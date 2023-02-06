# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMlExperimentsMetric < DatabaseMetric
          operation :count

          relation { Ml::Experiment }
        end
      end
    end
  end
end
