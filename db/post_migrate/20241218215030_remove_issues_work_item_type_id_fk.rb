# frozen_string_literal: true

class RemoveIssuesWorkItemTypeIdFk < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.8'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :issues, column: :work_item_type_id
    end
  end

  def down
    add_concurrent_foreign_key :issues,
      :work_item_types,
      column: :work_item_type_id,
      target_column: :id,
      on_delete: nil
  end
end
