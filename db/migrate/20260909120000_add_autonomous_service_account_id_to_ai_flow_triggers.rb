# frozen_string_literal: true

class AddAutonomousServiceAccountIdToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :ai_flow_triggers, :autonomous_service_account_id, :bigint
  end
end
