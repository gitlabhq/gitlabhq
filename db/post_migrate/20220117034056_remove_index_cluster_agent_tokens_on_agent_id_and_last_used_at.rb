# frozen_string_literal: true

class RemoveIndexClusterAgentTokensOnAgentIdAndLastUsedAt < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX = 'index_cluster_agent_tokens_on_agent_id_and_last_used_at'

  def up
    remove_concurrent_index_by_name :cluster_agent_tokens, name: INDEX
  end

  def down
    add_concurrent_index :cluster_agent_tokens, 'agent_id, last_used_at DESC NULLS LAST', name: INDEX
  end
end
