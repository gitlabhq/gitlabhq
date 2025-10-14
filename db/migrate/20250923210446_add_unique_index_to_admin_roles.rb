# frozen_string_literal: true

class AddUniqueIndexToAdminRoles < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  OLD_INDEX_NAME = 'index_admin_roles_on_name'
  NEW_INDEX_NAME = 'index_admin_roles_on_organization_id_and_name'

  def up
    add_concurrent_index :admin_roles, [:organization_id, :name], unique: true, name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :admin_roles, OLD_INDEX_NAME, if_exists: true
  end

  def down
    add_concurrent_index :admin_roles, :name, name: OLD_INDEX_NAME, unique: true
    remove_concurrent_index_by_name :admin_roles, NEW_INDEX_NAME, if_exists: true
  end
end
