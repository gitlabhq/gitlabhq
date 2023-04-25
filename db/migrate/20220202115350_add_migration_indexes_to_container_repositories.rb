# frozen_string_literal: true

class AddMigrationIndexesToContainerRepositories < Gitlab::Database::Migration[1.0]
  PRE_IMPORTING_INDEX = 'idx_container_repos_on_pre_import_started_at_when_pre_importing'
  PRE_IMPORT_DONE_INDEX = 'idx_container_repos_on_pre_import_done_at_when_pre_import_done'
  IMPORTING_INDEX = 'idx_container_repos_on_import_started_at_when_importing'

  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories, :migration_pre_import_started_at, name: PRE_IMPORTING_INDEX, where: "migration_state = 'pre_importing'"
    add_concurrent_index :container_repositories, :migration_pre_import_done_at, name: PRE_IMPORT_DONE_INDEX, where: "migration_state = 'pre_import_done'"
    add_concurrent_index :container_repositories, :migration_import_started_at, name: IMPORTING_INDEX, where: "migration_state = 'importing'"
  end

  def down
    remove_concurrent_index_by_name :container_repositories, IMPORTING_INDEX
    remove_concurrent_index_by_name :container_repositories, PRE_IMPORT_DONE_INDEX
    remove_concurrent_index_by_name :container_repositories, PRE_IMPORTING_INDEX
  end
end
