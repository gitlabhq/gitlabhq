# frozen_string_literal: true

class AddAuthorityStateIndexToImportSyncRepositories < Gitlab::Database::Migration[2.3]
  milestone '19.6'
  disable_ddl_transaction!

  TABLE = :import_sync_repositories
  INDEX_NAME = 'index_import_sync_repositories_on_authority_state_and_id'

  def up
    add_concurrent_index TABLE, [:authority_state, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE, INDEX_NAME
  end
end
