# frozen_string_literal: true

class AddForeignKeyToGroupIdOnDependencyListExports < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :dependency_list_exports,
      :namespaces,
      column: :group_id,
      on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    remove_foreign_key_if_exists :dependency_list_exports, column: :group_id
  end
end
