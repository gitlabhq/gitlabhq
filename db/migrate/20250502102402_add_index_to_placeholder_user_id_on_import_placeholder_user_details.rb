# frozen_string_literal: true

class AddIndexToPlaceholderUserIdOnImportPlaceholderUserDetails < Gitlab::Database::Migration[2.3]
  milestone '18.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_import_placeholder_user_details_on_placeholder_user_id'

  def up
    add_concurrent_index :import_placeholder_user_details, :placeholder_user_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :import_placeholder_user_details, INDEX_NAME
  end
end
