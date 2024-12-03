# frozen_string_literal: true

class IndexWorkItemProgressesOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  INDEX_NAME = 'index_work_item_progresses_on_namespace_id'

  def up
    add_concurrent_index :work_item_progresses, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_progresses, INDEX_NAME
  end
end
