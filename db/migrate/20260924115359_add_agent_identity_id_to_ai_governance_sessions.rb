# frozen_string_literal: true

class AddAgentIdentityIdToAiGovernanceSessions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :ai_governance_sessions, :agent_identity_id, :bigint
  end
end
