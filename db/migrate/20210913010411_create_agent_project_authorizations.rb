# frozen_string_literal: true

class CreateAgentProjectAuthorizations < Gitlab::Database::Migration[1.0]
  def change
    create_table :agent_project_authorizations do |t|
      t.bigint :project_id, null: false
      t.bigint :agent_id, null: false
      t.jsonb :config, null: false

      t.index :project_id
      t.index [:agent_id, :project_id], unique: true
    end
  end
end
