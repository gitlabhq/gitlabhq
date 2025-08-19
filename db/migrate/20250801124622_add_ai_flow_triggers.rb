# frozen_string_literal: true

class AddAiFlowTriggers < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    create_table :ai_flow_triggers do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: true

      t.text :config_path, limit: 255, null: true
      t.text :description, limit: 255, null: false
      t.column :event_types, :smallint, array: true, default: [], null: false

      t.timestamps_with_timezone null: false

      t.index :user_id
      t.index :project_id
    end
  end

  def down
    drop_table :ai_flow_triggers
  end
end
