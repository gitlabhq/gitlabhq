# frozen_string_literal: true

class AddIndexOnAiFlowTriggersAutonomousServiceAccountId < Gitlab::Database::Migration[2.3]
  milestone '19.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_flow_triggers_on_autonomous_service_account_id'

  # Only autonomous triggers set this column, so the index stays tiny. A lookup
  # by account implies IS NOT NULL, so the planner still uses it.
  def up
    add_concurrent_index :ai_flow_triggers, :autonomous_service_account_id,
      name: INDEX_NAME, where: 'autonomous_service_account_id IS NOT NULL'
  end

  def down
    remove_concurrent_index_by_name :ai_flow_triggers, INDEX_NAME
  end
end
