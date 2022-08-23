# frozen_string_literal: true

class UpdateTmpNonMigratedIndexOnContainerRepositories < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  NEW_INDEX_NAME = 'tmp_index_container_repos_on_non_migrated'
  OLD_INDEX_NAME = 'tmp_idx_container_repos_on_non_migrated'
  MIGRATION_PHASE_1_ENDED_AT = '2022-01-23'

  def up
    add_concurrent_index :container_repositories,
                         [:project_id, :id],
                         name: NEW_INDEX_NAME,
                         where: "migration_state != 'import_done'"
    remove_concurrent_index_by_name :container_repositories, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :container_repositories,
                         [:project_id, :id],
                         name: OLD_INDEX_NAME,
                         where: "migration_state != 'import_done' AND created_at < '#{MIGRATION_PHASE_1_ENDED_AT}'"
    remove_concurrent_index_by_name :container_repositories, NEW_INDEX_NAME
  end
end
