# frozen_string_literal: true

class AddAgentIdColumnToEnvironments < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :environments, :cluster_agent_id, :bigint, null: true
  end
end
