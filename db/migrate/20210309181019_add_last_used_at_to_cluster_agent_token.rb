# frozen_string_literal: true

class AddLastUsedAtToClusterAgentToken < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :cluster_agent_tokens, :last_used_at, :datetime_with_timezone
  end
end
