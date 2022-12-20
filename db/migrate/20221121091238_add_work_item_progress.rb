# frozen_string_literal: true

class AddWorkItemProgress < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :work_item_progresses, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :issue, primary_key: true, index: false, default: nil,
                           foreign_key: { on_delete: :cascade, to_table: :issues }
      t.integer :progress, default: 0, limit: 2, null: false
    end
  end

  def down
    drop_table :work_item_progresses
  end
end
