# frozen_string_literal: true

class CreateWorkItemDecisionOptions < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    create_table :work_item_decision_options do |t|
      t.bigint :work_item_decision_id, null: false
      t.bigint :namespace_id, null: false

      t.timestamps_with_timezone null: false

      t.boolean :recommended, null: false, default: false
      t.boolean :selected, null: false, default: false

      t.text :content, null: false, limit: 1024
      t.text :description, limit: 2048

      t.index :work_item_decision_id
      t.index :namespace_id

      t.foreign_key :work_item_decisions, column: :work_item_decision_id, on_delete: :cascade
    end
  end

  def down
    drop_table :work_item_decision_options
  end
end
