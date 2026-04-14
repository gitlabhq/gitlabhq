# frozen_string_literal: true

class AddWorkItemPositionsWorkItemForeignKey < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_positions, :issues,
      column: :work_item_id, on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_positions, column: :work_item_id
    end
  end
end
