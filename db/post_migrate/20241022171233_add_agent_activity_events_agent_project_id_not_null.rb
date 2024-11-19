# frozen_string_literal: true

class AddAgentActivityEventsAgentProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :agent_activity_events, :agent_project_id
  end

  def down
    remove_not_null_constraint :agent_activity_events, :agent_project_id
  end
end
