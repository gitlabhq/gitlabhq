# frozen_string_literal: true

class CreateWorkspaceAgentkStatesTable < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    create_table :workspace_agentk_states do |t|
      t.timestamps_with_timezone null: false
      t.bigint :workspace_id, null: false, index: { unique: true }
      t.bigint :project_id, null: false, index: true
      t.jsonb :desired_config, null: false
    end
  end

  def down
    drop_table :workspace_agentk_states
  end
end
