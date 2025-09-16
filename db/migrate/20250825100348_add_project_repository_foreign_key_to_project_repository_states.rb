# frozen_string_literal: true

class AddProjectRepositoryForeignKeyToProjectRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_repository_states_on_project_repository_id'

  def up
    add_concurrent_index :project_repository_states, :project_repository_id, name: INDEX_NAME

    add_concurrent_foreign_key :project_repository_states, :project_repositories,
      column: :project_repository_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_repository_states, :project_repositories
    end

    remove_concurrent_index :project_repository_states, :project_repository_id, name: INDEX_NAME
  end
end
