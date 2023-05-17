# frozen_string_literal: true

class IndexGroupIdOnDependencyListExports < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_dependency_list_exports_on_group_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :dependency_list_exports, :group_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dependency_list_exports, INDEX_NAME
  end
end
