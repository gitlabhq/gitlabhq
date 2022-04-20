# frozen_string_literal: true

class UpdateIndexOnGreatedDoneAtOnContainerRepositories < Gitlab::Database::Migration[1.0]
  OLD_INDEX_NAME = 'index_container_repositories_on_greatest_done_at'
  NEW_INDEX_NAME = 'index_container_repositories_on_greatest_completed_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories,
      'GREATEST(migration_pre_import_done_at, migration_import_done_at, migration_aborted_at, migration_skipped_at)',
      where: "migration_state IN ('import_done', 'pre_import_done', 'import_aborted', 'import_skipped')",
      name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :container_repositories, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :container_repositories,
      'GREATEST(migration_pre_import_done_at, migration_import_done_at, migration_aborted_at)',
      where: "migration_state IN ('import_done', 'pre_import_done', 'import_aborted')",
      name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :container_repositories, NEW_INDEX_NAME
  end
end
