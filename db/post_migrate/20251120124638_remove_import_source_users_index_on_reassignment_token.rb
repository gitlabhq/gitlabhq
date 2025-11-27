# frozen_string_literal: true

class RemoveImportSourceUsersIndexOnReassignmentToken < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_source_users_on_reassignment_token'

  def up
    remove_concurrent_index_by_name :import_source_users, INDEX_NAME
  end

  def down
    add_concurrent_index :import_source_users,
      :reassignment_token,
      unique: true,
      name: INDEX_NAME
  end
end
