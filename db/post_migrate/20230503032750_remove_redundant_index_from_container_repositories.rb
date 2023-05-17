# frozen_string_literal: true

class RemoveRedundantIndexFromContainerRepositories < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_container_repositories_on_project_id'

  def up
    remove_concurrent_index_by_name :container_repositories, INDEX_NAME
  end

  def down
    add_concurrent_index :container_repositories, :project_id, name: INDEX_NAME
  end
end
