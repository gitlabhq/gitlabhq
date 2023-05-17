# frozen_string_literal: true

class ValidateFkMlCandidateParamsOnCandidateId < Gitlab::Database::Migration[2.1]
  NEW_CONSTRAINT_NAME = 'fk_ml_candidate_params_on_candidate_id'

  def up
    validate_foreign_key(:ml_candidate_params, :candidate_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
