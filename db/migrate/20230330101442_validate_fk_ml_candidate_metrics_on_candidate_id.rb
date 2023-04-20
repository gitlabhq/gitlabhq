# frozen_string_literal: true

class ValidateFkMlCandidateMetricsOnCandidateId < Gitlab::Database::Migration[2.1]
  NEW_CONSTRAINT_NAME = 'fk_ml_candidate_metrics_on_candidate_id'

  def up
    validate_foreign_key(:ml_candidate_metrics, :candidate_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
