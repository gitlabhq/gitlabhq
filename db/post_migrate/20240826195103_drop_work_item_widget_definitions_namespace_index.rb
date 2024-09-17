# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsNamespaceIndex < Gitlab::Database::Migration[2.2]
  UNIQUE_INDEX_NAME = 'index_work_item_widget_definitions_on_namespace_type_and_name'

  milestone '17.4'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :work_item_widget_definitions, name: UNIQUE_INDEX_NAME
  end

  def down
    add_concurrent_index :work_item_widget_definitions,
      [:namespace_id, :work_item_type_id, :name],
      unique: true,
      name: UNIQUE_INDEX_NAME
  end
end
