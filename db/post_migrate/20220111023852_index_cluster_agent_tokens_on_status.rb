# frozen_string_literal: true

class IndexClusterAgentTokensOnStatus < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_cluster_agent_tokens_on_agent_id_status_last_used_at'

  def up
    add_concurrent_index :cluster_agent_tokens, 'agent_id, status, last_used_at DESC NULLS LAST', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :cluster_agent_tokens, INDEX_NAME
  end
end
