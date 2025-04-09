# frozen_string_literal: true

class AddUserForeignKeyToUserAdminRoles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :user_admin_roles, :users, column: :user_id, on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :user_admin_roles, column: :user_id, reverse_lock_order: true
    end
  end
end
