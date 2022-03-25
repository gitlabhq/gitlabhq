# frozen_string_literal: true

class AddMigrationPlanIndexToContainerRepositories < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'idx_container_repos_on_migration_state_migration_plan_created'

  disable_ddl_transaction!

  def up
    add_concurrent_index :container_repositories,
      [:migration_state, :migration_plan, :created_at],
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end
end
