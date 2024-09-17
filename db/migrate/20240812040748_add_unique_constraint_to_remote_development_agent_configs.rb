# frozen_string_literal: true

class AddUniqueConstraintToRemoteDevelopmentAgentConfigs < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.4'
  INDEX_NAME = 'index_remote_development_agent_configs_on_unique_agent_id'
  EXISTING_INDEX_NAME = 'index_remote_development_agent_configs_on_cluster_agent_id'

  def up
    add_concurrent_index :remote_development_agent_configs, :cluster_agent_id, name: INDEX_NAME, unique: true
    remove_concurrent_index_by_name :remote_development_agent_configs, EXISTING_INDEX_NAME
  end

  def down
    add_concurrent_index :remote_development_agent_configs, :cluster_agent_id, name: EXISTING_INDEX_NAME
    remove_concurrent_index_by_name :remote_development_agent_configs, INDEX_NAME
  end
end
