# frozen_string_literal: true

class IndexRemoteDevelopmentAgentConfigsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_remote_development_agent_configs_on_project_id'

  def up
    add_concurrent_index :remote_development_agent_configs, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :remote_development_agent_configs, INDEX_NAME
  end
end
