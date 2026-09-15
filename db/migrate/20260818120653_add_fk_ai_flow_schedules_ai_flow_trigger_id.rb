# frozen_string_literal: true

class AddFkAiFlowSchedulesAiFlowTriggerId < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ai_flow_schedules, :ai_flow_triggers, column: :ai_flow_trigger_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_flow_schedules, column: :ai_flow_trigger_id
    end
  end
end
