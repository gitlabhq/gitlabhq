# frozen_string_literal: true

class AddFkAiComplianceAnthropicSessionsToIntegrations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.6'

  def up
    add_concurrent_foreign_key :ai_compliance_anthropic_sessions, :ai_compliance_anthropic_integrations,
      column: :anthropic_integration_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_compliance_anthropic_sessions, column: :anthropic_integration_id
    end
  end
end
