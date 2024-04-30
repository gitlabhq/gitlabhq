# frozen_string_literal: true

class AddWorkItemParentLinksNamespaceIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_parent_links, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :work_item_parent_links, column: :namespace_id
    end
  end
end
