# frozen_string_literal: true

class CreateAgentUserAccessProjectAuthorizationsTable < Gitlab::Database::Migration[2.1]
  INDEX_NAME_1 = 'index_agent_user_access_on_project_id'
  INDEX_NAME_2 = 'index_agent_user_access_on_agent_id_and_project_id'

  def change
    create_table :agent_user_access_project_authorizations do |t|
      t.bigint :project_id, null: false
      t.bigint :agent_id, null: false
      t.jsonb :config, null: false

      t.index [:project_id], name: INDEX_NAME_1
      t.index [:agent_id, :project_id], unique: true, name: INDEX_NAME_2
    end
  end
end
