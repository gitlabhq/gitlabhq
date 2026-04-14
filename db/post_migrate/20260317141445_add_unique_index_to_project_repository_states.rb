# frozen_string_literal: true

class AddUniqueIndexToProjectRepositoryStates < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.11'

  UNIQUE_INDEX_NAME = 'unique_index_project_repository_states_on_project_repository_id'
  INDEX_NAME = 'index_project_repository_states_on_project_repository_id'

  def up
    add_concurrent_index :project_repository_states, :project_repository_id,
      name: UNIQUE_INDEX_NAME,
      unique: true

    remove_concurrent_index_by_name :project_repository_states, INDEX_NAME
  end

  def down
    add_concurrent_index :project_repository_states, :project_repository_id,
      name: INDEX_NAME

    remove_concurrent_index_by_name :project_repository_states, UNIQUE_INDEX_NAME
  end
end
