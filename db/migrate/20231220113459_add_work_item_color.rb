# frozen_string_literal: true

class AddWorkItemColor < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.8'

  def up
    create_table :work_item_colors, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :issue, primary_key: true, index: false, default: nil,
        foreign_key: { on_delete: :cascade, to_table: :issues }
      t.bigint :namespace_id, null: false
      t.text :color, null: false, limit: 7
    end
  end

  def down
    drop_table :work_item_colors
  end
end
