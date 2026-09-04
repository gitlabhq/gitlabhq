# frozen_string_literal: true

class CreateWorkItemDecisions < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    create_table :work_item_decisions do |t|
      t.bigint :work_item_id, null: false
      t.bigint :namespace_id, null: false
      t.bigint :author_id
      t.bigint :resolved_by_id
      t.bigint :resolving_note_id
      t.bigint :workflow_id

      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :resolved_at

      t.text :title, null: false, limit: 255
      t.text :description, limit: 3000
      t.text :resolution_rationale, limit: 3000
      t.text :discussion_id, limit: 255
      t.text :source_link, limit: 2048

      t.index :work_item_id
      t.index :namespace_id
      t.index :author_id
      t.index :resolved_by_id
      t.index :resolving_note_id
      t.index :workflow_id
    end
  end

  def down
    drop_table :work_item_decisions
  end
end
