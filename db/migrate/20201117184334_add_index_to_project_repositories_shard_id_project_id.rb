# frozen_string_literal: true

class AddIndexToProjectRepositoriesShardIdProjectId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_repositories, [:shard_id, :project_id]
  end

  def down
    remove_concurrent_index :project_repositories, [:shard_id, :project_id], name: 'index_project_repositories_on_shard_id_and_project_id'
  end
end
