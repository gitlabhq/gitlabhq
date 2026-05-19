# frozen_string_literal: true

class AddIndexToAiFlowTriggersOnUserIdAndProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  INDEX_NAME = 'index_ai_flow_triggers_on_user_id_and_project_id'
  OLD_INDEX_NAME = 'index_ai_flow_triggers_on_user_id'

  def up
    add_concurrent_index :ai_flow_triggers, [:user_id, :project_id], name: INDEX_NAME

    remove_concurrent_index_by_name :ai_flow_triggers, OLD_INDEX_NAME, if_exists: true
  end

  def down
    add_concurrent_index :ai_flow_triggers, :user_id, name: OLD_INDEX_NAME

    remove_concurrent_index_by_name :ai_flow_triggers, INDEX_NAME, if_exists: true
  end
end
