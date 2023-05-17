# frozen_string_literal: true

class RemoveOldFkMlCandidateParamsOnCandidateId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'fk_rails_d4a51d1185'

  def up
    remove_foreign_key_if_exists(:ml_candidate_params, column: :candidate_id, name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :ml_candidate_params,
      :ml_candidates,
      column: :candidate_id,
      validate: false,
      name: OLD_CONSTRAINT_NAME
    )
  end
end
