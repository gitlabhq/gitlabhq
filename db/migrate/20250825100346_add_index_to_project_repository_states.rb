# frozen_string_literal: true

class AddIndexToProjectRepositoryStates < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_project_repository_states_on_project_id'

  def up
    add_concurrent_index :project_repository_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :project_repository_states, :project_id, name: INDEX_NAME
  end
end
