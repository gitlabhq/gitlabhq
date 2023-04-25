# frozen_string_literal: true

class CreateRelatedEpicLinks < Gitlab::Database::Migration[1.0]
  def up
    create_table :related_epic_links do |t|
      t.references :source, index: true, foreign_key: { to_table: :epics, on_delete: :cascade }, null: false
      t.references :target, index: true, foreign_key: { to_table: :epics, on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.integer :link_type, null: false, default: 0, limit: 2

      t.index [:source_id, :target_id], unique: true
    end
  end

  def down
    drop_table :related_epic_links
  end
end
