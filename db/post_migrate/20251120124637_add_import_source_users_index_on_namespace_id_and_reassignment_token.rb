# frozen_string_literal: true

class AddImportSourceUsersIndexOnNamespaceIdAndReassignmentToken < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_source_users_on_namespace_id_reassignment_token'

  def up
    add_concurrent_index :import_source_users,
      [:namespace_id, :reassignment_token],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :import_source_users, INDEX_NAME
  end
end
