# frozen_string_literal: true

class AddBackIssuesWorkItemTypeIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  DEPENDENT_BATCHED_BACKGROUND_MIGRATIONS = [20250106173236]

  milestone '17.9'

  def up
    add_concurrent_foreign_key :issues,
      :work_item_types,
      column: :work_item_type_id,
      target_column: :id,
      reverse_lock_order: true,
      on_delete: nil
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :issues, column: :work_item_type_id
    end
  end
end
