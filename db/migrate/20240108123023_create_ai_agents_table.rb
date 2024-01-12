# frozen_string_literal: true

class CreateAiAgentsTable < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def change
    create_table :ai_agents do |t|
      t.timestamps_with_timezone null: false
      # Queries by project_id are covered by the project_id, name index
      # because project_id is the leftmost column.
      t.references :project, foreign_key: { on_delete: :cascade }, index: false, null: false

      t.text :name, limit: 255, null: false

      t.index [:project_id, :name], unique: true
    end
  end
end
