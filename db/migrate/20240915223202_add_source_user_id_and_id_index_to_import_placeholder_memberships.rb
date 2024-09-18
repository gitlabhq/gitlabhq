# frozen_string_literal: true

class AddSourceUserIdAndIdIndexToImportPlaceholderMemberships < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.5'

  INDEX_NAME = 'idx_import_placeholder_memberships_on_source_user_id_and_id'

  def up
    add_concurrent_index :import_placeholder_memberships, [:source_user_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :import_placeholder_memberships, INDEX_NAME
  end
end
