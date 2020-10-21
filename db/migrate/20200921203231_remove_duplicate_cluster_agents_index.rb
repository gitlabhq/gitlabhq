# frozen_string_literal: true

class RemoveDuplicateClusterAgentsIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX = 'index_cluster_agents_on_project_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :cluster_agents, INDEX
  end

  def down
    add_concurrent_index :cluster_agents, :project_id, name: INDEX
  end
end
