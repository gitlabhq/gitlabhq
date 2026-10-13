# frozen_string_literal: true

class AddLastSuccessfulSyncAtToAiComplianceAnthropicIntegrations < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :ai_compliance_anthropic_integrations, :last_successful_sync_at, :datetime_with_timezone
  end
end
