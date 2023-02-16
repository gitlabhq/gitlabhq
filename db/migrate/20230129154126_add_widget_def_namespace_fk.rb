# frozen_string_literal: true

class AddWidgetDefNamespaceFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_widget_definitions, :work_item_types,
      column: :work_item_type_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_widget_definitions, column: :work_item_type_id
    end
  end
end
