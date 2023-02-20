# frozen_string_literal: true

class AddWidgetDefWorkItemTypeFk < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_widget_definitions, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_widget_definitions, column: :namespace_id
    end
  end
end
