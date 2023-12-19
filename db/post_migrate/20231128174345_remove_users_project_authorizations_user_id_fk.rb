# frozen_string_literal: true

class RemoveUsersProjectAuthorizationsUserIdFk < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_rails_11e7aa3ed9"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:project_authorizations, :users,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:project_authorizations, :users,
      name: FOREIGN_KEY_NAME, column: :user_id,
      target_column: :id, on_delete: :cascade)
  end
end
