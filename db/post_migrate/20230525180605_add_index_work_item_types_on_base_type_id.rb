# frozen_string_literal: true

class AddIndexWorkItemTypesOnBaseTypeId < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_work_item_types_on_base_type_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :work_item_types, [:base_type, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_types, INDEX_NAME
  end
end
