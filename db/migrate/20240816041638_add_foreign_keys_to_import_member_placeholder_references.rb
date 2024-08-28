# frozen_string_literal: true

class AddForeignKeysToImportMemberPlaceholderReferences < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :import_placeholder_memberships, :namespaces, column: :namespace_id,
      on_delete: :cascade, reverse_lock_order: true
    add_concurrent_foreign_key :import_placeholder_memberships, :projects, column: :project_id,
      on_delete: :cascade, reverse_lock_order: true
    add_concurrent_foreign_key :import_placeholder_memberships, :namespaces, column: :group_id,
      on_delete: :cascade, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :import_placeholder_memberships, column: :group_id, reverse_lock_order: true
      remove_foreign_key_if_exists :import_placeholder_memberships, column: :project_id, reverse_lock_order: true
      remove_foreign_key_if_exists :import_placeholder_memberships, column: :namespace_id, reverse_lock_order: true
    end
  end
end
