# frozen_string_literal: true

class AddNamespaceAiSettingsTable < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  def up
    create_table :namespace_ai_settings, id: false do |t|
      t.references :namespace, primary_key: true, default: nil, null: false,
        index: { unique: true }, foreign_key: { on_delete: :cascade }

      t.boolean :duo_workflow_mcp_enabled, default: false, null: false
    end
  end

  def down
    drop_table :namespace_ai_settings
  end
end
