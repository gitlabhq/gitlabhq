# frozen_string_literal: true

class CreateResourceLinkEvents < Gitlab::Database::Migration[2.1]
  def change
    create_table :resource_link_events do |t|
      t.integer :action, limit: 2, null: false
      t.bigint :user_id, null: false
      t.references :issue, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :child_work_item, index: true, null: false, foreign_key: { to_table: :issues, on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false

      t.index :user_id
    end
  end
end
