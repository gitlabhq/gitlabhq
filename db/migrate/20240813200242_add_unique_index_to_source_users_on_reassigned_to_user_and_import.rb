# frozen_string_literal: true

class AddUniqueIndexToSourceUsersOnReassignedToUserAndImport < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'

  INDEX_NAME = 'unique_import_source_users_on_reassign_to_user_id_and_import'
  PREVIOUS_INDEX_NAME = 'index_import_source_users_on_reassign_to_user_id'

  def up
    add_concurrent_index(
      :import_source_users,
      [:reassign_to_user_id, :namespace_id, :source_hostname, :import_type],
      unique: true,
      name: INDEX_NAME
    )
    remove_concurrent_index_by_name :import_source_users, PREVIOUS_INDEX_NAME
  end

  def down
    add_concurrent_index :import_source_users, [:reassign_to_user_id], name: PREVIOUS_INDEX_NAME
    remove_concurrent_index_by_name :import_source_users, INDEX_NAME
  end
end
