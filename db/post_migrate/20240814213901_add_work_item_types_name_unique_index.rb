# frozen_string_literal: true

class AddWorkItemTypesNameUniqueIndex < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_work_item_types_on_name_unique'

  disable_ddl_transaction!

  milestone '17.4'

  def up
    add_concurrent_index :work_item_types,
      'TRIM(BOTH FROM LOWER(name))',
      name: INDEX_NAME,
      unique: true
  end

  def down
    remove_concurrent_index_by_name :work_item_types, INDEX_NAME
  end
end
