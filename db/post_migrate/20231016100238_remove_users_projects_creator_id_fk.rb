# frozen_string_literal: true

class RemoveUsersProjectsCreatorIdFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_03ec10b0d3"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:projects, :users,
      name: FOREIGN_KEY_NAME, column: :creator_id,
      target_column: :id, on_delete: :nullify)
  end
end
