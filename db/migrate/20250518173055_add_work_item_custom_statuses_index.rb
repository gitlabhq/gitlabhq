# frozen_string_literal: true

class AddWorkItemCustomStatusesIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  INDEX_NAME = 'index_work_item_custom_statuses_on_namespace_id_and_lower_name'

  milestone '18.1'

  def up
    add_concurrent_index :work_item_custom_statuses,
      'namespace_id, TRIM(BOTH FROM lower(name))',
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_custom_statuses, INDEX_NAME
  end
end
