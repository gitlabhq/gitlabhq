# frozen_string_literal: true

class AddIndexOnMigrationStateAndImportDoneAtToContainerRepositories < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_container_repositories_on_migration_state_import_done_at'
  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories, [:migration_state, :migration_import_done_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end
end
