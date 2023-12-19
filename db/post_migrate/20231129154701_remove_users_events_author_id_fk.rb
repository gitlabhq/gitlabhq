# frozen_string_literal: true

class RemoveUsersEventsAuthorIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  FOREIGN_KEY_NAME = "fk_edfd187b6f"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:events, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:events, :users,
      name: FOREIGN_KEY_NAME, column: :author_id,
      target_column: :id, on_delete: :cascade)
  end
end
