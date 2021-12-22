# frozen_string_literal: true

class AddStatusToClusterAgentTokens < Gitlab::Database::Migration[1.0]
  def change
    add_column :cluster_agent_tokens, :status, :smallint, null: false, default: 0
  end
end
