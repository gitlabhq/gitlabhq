# frozen_string_literal: true

class CreateUserAdminRoles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  def up
    create_table :user_admin_roles, primary_key: [:user_id] do |t|
      t.bigint :user_id, null: false
      t.bigint :admin_role_id, null: false
      t.timestamps_with_timezone null: false
      t.boolean :ldap, null: false, default: false
    end

    add_concurrent_index :user_admin_roles, :admin_role_id
  end

  def down
    drop_table :user_admin_roles
  end
end
