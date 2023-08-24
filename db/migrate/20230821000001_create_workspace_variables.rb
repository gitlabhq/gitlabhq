# frozen_string_literal: true

class CreateWorkspaceVariables < Gitlab::Database::Migration[2.1]
  def change
    create_table :workspace_variables do |t|
      t.references :workspace, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.integer :variable_type, null: false, limit: 2
      t.timestamps_with_timezone null: false
      t.text :key, null: false, limit: 255
      t.binary :encrypted_value, null: false
      t.binary :encrypted_value_iv, null: false
    end
  end
end
