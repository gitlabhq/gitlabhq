# frozen_string_literal: true

class AddAdminRoleForeignKeyToUserAdminRoles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    add_concurrent_foreign_key :user_admin_roles, :admin_roles, column: :admin_role_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :user_admin_roles, column: :admin_role_id
    end
  end
end
