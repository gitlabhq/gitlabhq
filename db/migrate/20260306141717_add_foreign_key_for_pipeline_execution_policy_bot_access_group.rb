# frozen_string_literal: true

class AddForeignKeyForPipelineExecutionPolicyBotAccessGroup < Gitlab::Database::Migration[2.3]
  milestone '18.11'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :project_settings, :namespaces,
      column: :pipeline_execution_policy_bot_access_group_id,
      on_delete: :nullify
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :project_settings, column: :pipeline_execution_policy_bot_access_group_id
    end
  end
end
