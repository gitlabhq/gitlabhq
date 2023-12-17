# frozen_string_literal: true

class AddWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  def up
    create_table :work_item_dates_sources, id: false do |t|
      t.timestamps_with_timezone null: false
      t.references :issue,
        primary_key: true,
        index: false,
        default: nil,
        foreign_key: { on_delete: :cascade, to_table: :issues }

      t.bigint :namespace_id, null: false

      t.boolean :start_date_is_fixed, default: false, null: false
      t.boolean :due_date_is_fixed, default: false, null: false
      t.date :start_date, null: true
      t.date :due_date, null: true
      t.bigint :start_date_sourcing_work_item_id, null: true
      t.bigint :start_date_sourcing_milestone_id, null: true
      t.bigint :due_date_sourcing_work_item_id, null: true
      t.bigint :due_date_sourcing_milestone_id, null: true
    end
  end

  def down
    drop_table :work_item_dates_sources
  end
end
