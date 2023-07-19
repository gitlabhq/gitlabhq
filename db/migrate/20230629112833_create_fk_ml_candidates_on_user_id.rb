# frozen_string_literal: true

class CreateFkMlCandidatesOnUserId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NEW_CONSTRAINT_NAME = 'fk_ml_candidates_on_user_id'

  def up
    add_concurrent_foreign_key(
      :ml_candidates,
      :users,
      column: :user_id,
      on_delete: :nullify,
      validate: false,
      name: NEW_CONSTRAINT_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        :ml_candidates,
        column: :user_id,
        on_delete: :nullify,
        name: NEW_CONSTRAINT_NAME
      )
    end
  end
end
