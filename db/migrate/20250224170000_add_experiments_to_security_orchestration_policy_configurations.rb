# frozen_string_literal: true

class AddExperimentsToSecurityOrchestrationPolicyConfigurations < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :security_orchestration_policy_configurations, :experiments, :jsonb, null: false, default: {}
  end
end
