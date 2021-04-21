# frozen_string_literal: true

class IndexClusterAgentTokensOnLastUsedAt < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  OLD_INDEX = 'index_cluster_agent_tokens_on_agent_id'
  NEW_INDEX = 'index_cluster_agent_tokens_on_agent_id_and_last_used_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :cluster_agent_tokens, 'agent_id, last_used_at DESC NULLS LAST', name: NEW_INDEX
    remove_concurrent_index_by_name :cluster_agent_tokens, OLD_INDEX
  end

  def down
    add_concurrent_index :cluster_agent_tokens, :agent_id, name: OLD_INDEX
    remove_concurrent_index_by_name :cluster_agent_tokens, NEW_INDEX
  end
end
