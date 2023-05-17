# frozen_string_literal: true

class AddBotUserIdToSecurityOrchestrationPolicyConfigurations < Gitlab::Database::Migration[2.1]
  def change
    add_column :security_orchestration_policy_configurations, :bot_user_id, :integer
  end
end
