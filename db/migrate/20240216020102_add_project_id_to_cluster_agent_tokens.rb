# frozen_string_literal: true

class AddProjectIdToClusterAgentTokens < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  enable_lock_retries!

  def change
    add_column :cluster_agent_tokens, :project_id, :bigint
  end
end
