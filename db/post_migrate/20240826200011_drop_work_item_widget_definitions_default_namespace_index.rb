# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsDefaultNamespaceIndex < Gitlab::Database::Migration[2.2]
  UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME = 'index_work_item_widget_definitions_on_default_witype_and_name'

  milestone '17.4'
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :work_item_widget_definitions, name: UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME
  end

  def down
    add_concurrent_index :work_item_widget_definitions,
      [:work_item_type_id, :name],
      where: "namespace_id is NULL",
      unique: true,
      name: UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME
  end
end
