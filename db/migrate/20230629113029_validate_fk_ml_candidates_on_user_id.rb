# frozen_string_literal: true

class ValidateFkMlCandidatesOnUserId < Gitlab::Database::Migration[2.1]
  NEW_CONSTRAINT_NAME = 'fk_ml_candidates_on_user_id'

  def up
    validate_foreign_key(:ml_candidates, :user_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
