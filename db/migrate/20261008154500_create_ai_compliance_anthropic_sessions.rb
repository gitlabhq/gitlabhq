# frozen_string_literal: true

class CreateAiComplianceAnthropicSessions < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  NAMESPACE_INDEX_NAME = 'i_anthropic_sessions_on_namespace_id'
  INTEGRATION_INDEX_NAME = 'i_anthropic_sessions_on_anthropic_integration_id'
  GOVERNANCE_SESSION_INDEX_NAME = 'i_anthropic_sessions_on_ai_governance_session_id'

  def change
    create_table :ai_compliance_anthropic_sessions do |t|
      t.bigint :namespace_id, null: false
      t.bigint :anthropic_integration_id, null: false
      t.bigint :ai_governance_session_id, null: false
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :walk_started_at
      t.text :session_xid, null: false, limit: 255
      t.text :message_watermark, limit: 255

      t.index :namespace_id, name: NAMESPACE_INDEX_NAME
      t.index :anthropic_integration_id, name: INTEGRATION_INDEX_NAME
      t.index :ai_governance_session_id, unique: true, name: GOVERNANCE_SESSION_INDEX_NAME
    end
  end
end
