# frozen_string_literal: true

class AddAgentProjectIdToAgentActivityEvents < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :agent_activity_events, :agent_project_id, :bigint
  end
end
