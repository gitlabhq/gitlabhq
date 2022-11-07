# frozen_string_literal: true

class AddStatusAndIdIndexToContainerRepositories < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_container_repositories_on_status_and_id'

  def up
    add_concurrent_index :container_repositories, [:status, :id], name: INDEX_NAME, where: 'status IS NOT NULL'
  end

  def down
    remove_concurrent_index :container_repositories, [:status, :id], name: INDEX_NAME
  end
end
