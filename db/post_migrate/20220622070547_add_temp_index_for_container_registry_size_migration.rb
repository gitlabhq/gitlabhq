# frozen_string_literal: true

class AddTempIndexForContainerRegistrySizeMigration < Gitlab::Database::Migration[2.0]
  INDEX_CONTAINER_REGISTRY_SIZE = 'tmp_index_migrated_container_registries'
  INDEX_PROJECT_STATS_CONT_REG_SIZE = 'tmp_index_project_statistics_cont_registry_size'

  disable_ddl_transaction!

  def up
    # Temporary index used in 20220622080547_backfill_project_statistics_with_container_registry_size
    # Temporary index to be remove via https://gitlab.com/gitlab-org/gitlab/-/issues/366392
    add_concurrent_index :container_repositories, [:project_id],
      name: INDEX_CONTAINER_REGISTRY_SIZE,
      where: "migration_state = 'import_done' OR created_at >= '2022-01-23'"
    add_concurrent_index :project_statistics, [:project_id],
      name: INDEX_PROJECT_STATS_CONT_REG_SIZE,
      where: "container_registry_size = 0"
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_CONTAINER_REGISTRY_SIZE
    remove_concurrent_index_by_name :project_statistics, INDEX_PROJECT_STATS_CONT_REG_SIZE
  end
end
