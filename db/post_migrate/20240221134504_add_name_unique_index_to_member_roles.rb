# frozen_string_literal: true

class AddNameUniqueIndexToMemberRoles < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  INDEX_WITH_NAMESPACE_NAME = 'index_member_roles_on_namespace_id_name_unique'
  INDEX_NO_NAMESPACE_NAME = 'index_member_roles_on_name_unique'

  def up
    add_concurrent_index :member_roles, [:namespace_id, :name], name: INDEX_WITH_NAMESPACE_NAME,
      unique: true, where: 'namespace_id IS NOT NULL'
    add_concurrent_index :member_roles, [:name], name: INDEX_NO_NAMESPACE_NAME,
      unique: true, where: 'namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :member_roles, INDEX_WITH_NAMESPACE_NAME
    remove_concurrent_index_by_name :member_roles, INDEX_NO_NAMESPACE_NAME
  end
end
