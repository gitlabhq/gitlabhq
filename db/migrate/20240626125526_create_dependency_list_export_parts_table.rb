# frozen_string_literal: true

class CreateDependencyListExportPartsTable < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    create_table :dependency_list_export_parts do |t|
      t.references :dependency_list_export, foreign_key: { on_delete: :cascade }, null: false, index: true
      t.bigint :start_id, null: false
      t.bigint :end_id, null: false
      t.references :organization, foreign_key: { on_delete: :cascade }, null: false, default: 1, index: true
      t.timestamps_with_timezone null: false
      t.integer :file_store
      t.text :file, limit: 255
    end
  end
end
