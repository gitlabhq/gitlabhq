# frozen_string_literal: true

class AddWorkItemTypeNameUniqueIndexNullNamespaces < Gitlab::Database::Migration[1.0]
  INDEX_NAME = :idx_work_item_types_on_namespace_id_and_name_null_namespace

  disable_ddl_transaction!

  def up
    add_concurrent_index :work_item_types,
                         'TRIM(BOTH FROM LOWER(name)), (namespace_id IS NULL)',
                         unique: true,
                         name: INDEX_NAME,
                         where: 'namespace_id IS NULL'
  end

  def down
    remove_concurrent_index_by_name :work_item_types, INDEX_NAME
  end
end
