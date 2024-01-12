# frozen_string_literal: true

class CreateAiAgentVersionsTable < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    create_table :ai_agent_versions do |t|
      t.timestamps_with_timezone null: false
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false

      t.bigint :agent_id, null: false # fk cascade

      t.text :prompt, limit: 5000, null: false
      t.text :model, limit: 255, null: false

      t.index :agent_id
    end
  end
end
