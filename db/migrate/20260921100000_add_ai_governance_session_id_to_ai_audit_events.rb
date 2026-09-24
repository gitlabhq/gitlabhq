# frozen_string_literal: true

class AddAiGovernanceSessionIdToAiAuditEvents < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :ai_audit_events, :ai_governance_session_id, :bigint
  end
end
