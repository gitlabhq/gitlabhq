# frozen_string_literal: true

class IndexContainerRepositoryStatesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_container_repository_states_on_project_id'

  def up
    add_concurrent_index :container_repository_states, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :container_repository_states, INDEX_NAME
  end
end
