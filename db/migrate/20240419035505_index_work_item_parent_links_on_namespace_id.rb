# frozen_string_literal: true

class IndexWorkItemParentLinksOnNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  INDEX_NAME = 'index_work_item_parent_links_on_namespace_id'

  def up
    add_concurrent_index :work_item_parent_links, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :work_item_parent_links, INDEX_NAME
  end
end
