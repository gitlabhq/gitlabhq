# frozen_string_literal: true

class RemoveSecurityOrchestrationPolicyConfigurationsBotUserIdColumn < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.7'

  TABLE = :security_orchestration_policy_configurations
  COLUMN = :bot_user_id
  INDEX = "index_security_policy_configurations_on_bot_user_id"

  def up
    remove_column(TABLE, COLUMN)
  end

  def down
    add_column(TABLE, COLUMN, :integer) unless column_exists?(TABLE, COLUMN)

    add_concurrent_foreign_key(TABLE, :users, column: COLUMN, on_delete: :nullify)

    add_concurrent_index(TABLE, COLUMN,
      where: "security_orchestration_policy_configurations.bot_user_id IS NOT NULL",
      name: INDEX)
  end
end
