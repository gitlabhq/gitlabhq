# frozen_string_literal: true

class RemoveDuplicatedProjectRepositoriesIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.10'

  INDEX_NAME = 'index_project_repositories_on_shard_id'

  def up
    remove_concurrent_index_by_name :project_repositories, name: INDEX_NAME
  end

  def down
    add_concurrent_index :project_repositories, :shard_id, name: INDEX_NAME
  end
end
