# frozen_string_literal: true

class IndexAgentActivityEventsOnAgentProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_agent_activity_events_on_agent_project_id'

  def up
    add_concurrent_index :agent_activity_events, :agent_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :agent_activity_events, INDEX_NAME
  end
end
