# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithMlCandidatesMetric < DatabaseMetric
          operation :distinct_count, column: 'ml_experiments.project_id'

          relation do
            Ml::Experiment.where('EXISTS (?)',
              Ml::Candidate.where("\"ml_experiments\".\"id\" = \"ml_candidates\".\"experiment_id\"").select(1))
          end
        end
      end
    end
  end
end
