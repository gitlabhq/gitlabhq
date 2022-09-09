# frozen_string_literal: true

class CreateDoraConfigurationTable < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    create_table :dora_configurations do |t|
      t.references :project, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.text :branches_for_lead_time_for_changes, null: false, array: true, default: []
    end
  end

  def down
    drop_table :dora_configurations
  end
end
