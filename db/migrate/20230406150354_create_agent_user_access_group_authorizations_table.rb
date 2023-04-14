# frozen_string_literal: true

class CreateAgentUserAccessGroupAuthorizationsTable < Gitlab::Database::Migration[2.1]
  INDEX_NAME_1 = 'index_agent_user_access_on_group_id'
  INDEX_NAME_2 = 'index_agent_user_access_on_agent_id_and_group_id'

  def change
    create_table :agent_user_access_group_authorizations do |t|
      t.bigint :group_id, null: false
      t.bigint :agent_id, null: false
      t.jsonb :config, null: false

      t.index [:group_id], name: INDEX_NAME_1
      t.index [:agent_id, :group_id], unique: true, name: INDEX_NAME_2
    end
  end
end
