# frozen_string_literal: true

class CreateAgentGroupAuthorizations < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def change
    create_table :agent_group_authorizations do |t|
      t.bigint :group_id, null: false
      t.bigint :agent_id, null: false
      t.jsonb :config, null: false

      t.index :group_id
      t.index [:agent_id, :group_id], unique: true
    end
  end
end
