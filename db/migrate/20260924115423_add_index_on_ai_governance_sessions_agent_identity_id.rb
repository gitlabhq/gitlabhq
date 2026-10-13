# frozen_string_literal: true

class AddIndexOnAiGovernanceSessionsAgentIdentityId < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_governance_sessions_on_agent_identity_id'

  def up
    add_concurrent_index :ai_governance_sessions, :agent_identity_id,
      name: INDEX_NAME, where: 'agent_identity_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :ai_governance_sessions, INDEX_NAME
  end
end
