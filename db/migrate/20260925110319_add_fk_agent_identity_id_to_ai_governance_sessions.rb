# frozen_string_literal: true

class AddFkAgentIdentityIdToAiGovernanceSessions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :ai_governance_sessions,
      :ai_agent_identities,
      column: :agent_identity_id,
      on_delete: :nullify
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_governance_sessions, column: :agent_identity_id
    end
  end
end
