# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountMlCandidatesMetric < DatabaseMetric
          operation :count

          relation { Ml::Candidate }
        end
      end
    end
  end
end
