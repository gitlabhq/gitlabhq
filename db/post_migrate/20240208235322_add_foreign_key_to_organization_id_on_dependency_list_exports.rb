# frozen_string_literal: true

class AddForeignKeyToOrganizationIdOnDependencyListExports < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_concurrent_foreign_key :dependency_list_exports, :organizations,
      column: :organization_id,
      on_delete: :cascade,
      reverse_lock_order: true
  end

  def down
    remove_foreign_key_if_exists :dependency_list_exports, column: :organization_id
  end
end
