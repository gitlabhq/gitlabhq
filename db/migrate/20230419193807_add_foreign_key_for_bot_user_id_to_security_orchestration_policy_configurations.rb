# frozen_string_literal: true

class AddForeignKeyForBotUserIdToSecurityOrchestrationPolicyConfigurations < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_security_policy_configurations_on_bot_user_id'

  def up
    add_concurrent_foreign_key :security_orchestration_policy_configurations, :users, column: :bot_user_id,
      on_delete: :nullify

    add_concurrent_index :security_orchestration_policy_configurations, :bot_user_id,
      where: "security_orchestration_policy_configurations.bot_user_id IS NOT NULL",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_orchestration_policy_configurations, INDEX_NAME

    with_lock_retries do
      remove_foreign_key_if_exists :security_orchestration_policy_configurations, column: :bot_user_id
    end
  end
end
