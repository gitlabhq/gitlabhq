# frozen_string_literal: true

class AddIndexOnGreatestDoneAtToContainerRepositories < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_container_repositories_on_greatest_done_at'
  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories,
                         'GREATEST(migration_pre_import_done_at, migration_import_done_at, migration_aborted_at)',
                         where: "migration_state IN ('import_done', 'pre_import_done', 'import_aborted')",
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end
end
