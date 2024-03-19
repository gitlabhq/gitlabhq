# frozen_string_literal: true

class IndexClusterAgentTokensOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  INDEX_NAME = 'index_cluster_agent_tokens_on_project_id'

  def up
    add_concurrent_index :cluster_agent_tokens, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cluster_agent_tokens, INDEX_NAME
  end
end
