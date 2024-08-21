# frozen_string_literal: true

class DropWorkItemTypesNamespaceId < Gitlab::Database::Migration[2.2]
  UNIQUE_INDEX_NAME = 'work_item_types_namespace_id_and_name_unique'
  UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME = 'idx_work_item_types_on_namespace_id_and_name_null_namespace'

  disable_ddl_transaction!

  milestone '17.4'

  def up
    remove_column :work_item_types, :namespace_id
  end

  def down
    add_column :work_item_types, :namespace_id, :bigint

    add_concurrent_index :work_item_types,
      'TRIM(BOTH FROM LOWER(name)), (namespace_id IS NULL)',
      unique: true,
      name: UNIQUE_DEFAULT_NAMESPACE_INDEX_NAME,
      where: 'namespace_id IS NULL'

    add_concurrent_index :work_item_types,
      'namespace_id, TRIM(BOTH FROM LOWER(name))',
      unique: true,
      name: UNIQUE_INDEX_NAME

    add_concurrent_foreign_key :work_item_types, :namespaces, column: :namespace_id, on_delete: :cascade
  end
end
