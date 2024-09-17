# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsNamespaceIdFk < Gitlab::Database::Migration[2.2]
  FK_NAME = 'fk_ecf57512f7'

  milestone '17.4'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        :work_item_widget_definitions,
        :namespaces,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_foreign_key :work_item_widget_definitions,
      :namespaces,
      column: :namespace_id,
      on_delete: :cascade,
      name: FK_NAME
  end
end
