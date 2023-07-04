# frozen_string_literal: true

class RemoveOldFkMlCandidatesOnUserId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'fk_rails_1b37441fe5'

  def up
    remove_foreign_key_if_exists(:ml_candidates, column: :user_id, name: OLD_CONSTRAINT_NAME)
  end

  def down
    add_concurrent_foreign_key(
      :ml_candidates,
      :users,
      column: :user_id,
      validate: false,
      name: OLD_CONSTRAINT_NAME
    )
  end
end
