# frozen_string_literal: true

class AddNonMigratedIndexToContainerRepositories < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  # follow up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/358407
  INDEX_NAME = 'tmp_idx_container_repos_on_non_migrated'
  MIGRATION_PHASE_1_ENDED_AT = '2022-01-23'

  def up
    add_concurrent_index :container_repositories,
                         [:project_id, :id],
                         name: INDEX_NAME,
                         where: "migration_state != 'import_done' AND created_at < '#{MIGRATION_PHASE_1_ENDED_AT}'"
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end
end
