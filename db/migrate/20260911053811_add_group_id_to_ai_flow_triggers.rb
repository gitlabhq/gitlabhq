# frozen_string_literal: true

class AddGroupIdToAiFlowTriggers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  INDEX_NAME = 'index_ai_flow_triggers_on_group_id'

  def up
    with_lock_retries do
      add_column :ai_flow_triggers, :group_id, :bigint, if_not_exists: true
    end

    add_concurrent_index :ai_flow_triggers, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_flow_triggers, INDEX_NAME

    with_lock_retries do
      remove_column :ai_flow_triggers, :group_id, if_exists: true
    end
  end
end
