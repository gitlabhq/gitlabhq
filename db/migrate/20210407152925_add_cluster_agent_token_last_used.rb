# frozen_string_literal: true

class AddClusterAgentTokenLastUsed < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  INDEX = 'index_cluster_agent_tokens_on_last_used_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :cluster_agent_tokens,
      :last_used_at,
      name: INDEX,
      order: { last_used_at: 'DESC NULLS LAST' }
  end

  def down
    remove_concurrent_index_by_name :cluster_agent_tokens, INDEX
  end
end
