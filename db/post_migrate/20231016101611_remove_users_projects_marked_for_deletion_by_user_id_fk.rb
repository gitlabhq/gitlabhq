# frozen_string_literal: true

class RemoveUsersProjectsMarkedForDeletionByUserIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_25d8780d11"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:projects, :users,
      name: FOREIGN_KEY_NAME, column: :marked_for_deletion_by_user_id,
      target_column: :id, on_delete: :nullify)
  end
end
