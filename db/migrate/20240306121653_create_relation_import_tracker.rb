# frozen_string_literal: true

class CreateRelationImportTracker < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    create_table :relation_import_trackers do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :relation, default: nil, limit: 2, null: false
      t.integer :status, default: 0, null: false, limit: 2
    end
  end
end
