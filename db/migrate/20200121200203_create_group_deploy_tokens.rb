# frozen_string_literal: true

class CreateGroupDeployTokens < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :group_deploy_tokens do |t|
      t.timestamps_with_timezone null: false

      t.references :group, index: false, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }
      t.references :deploy_token, null: false, foreign_key: { on_delete: :cascade }

      t.index [:group_id, :deploy_token_id], unique: true, name: 'index_group_deploy_tokens_on_group_and_deploy_token_ids'
    end
  end
end
