# frozen_string_literal: true

class AddAgentActivityEventsAgentProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :agent_activity_events, :projects, column: :agent_project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :agent_activity_events, column: :agent_project_id
    end
  end
end
