# frozen_string_literal: true

class AddIndexToAgentIdColumnEnvironments < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_environments_cluster_agent_id'

  def up
    add_concurrent_index :environments, :cluster_agent_id, name: INDEX_NAME, where: 'cluster_agent_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :environments, name: INDEX_NAME
  end
end
