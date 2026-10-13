# frozen_string_literal: true

class AddFkAiFlowTriggersGroupIdToNamespaces < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  def up
    add_concurrent_foreign_key :ai_flow_triggers, :namespaces, column: :group_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_flow_triggers, column: :group_id
    end
  end
end
