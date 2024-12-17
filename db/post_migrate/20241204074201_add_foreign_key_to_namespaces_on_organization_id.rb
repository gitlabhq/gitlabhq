# frozen_string_literal: true

class AddForeignKeyToNamespacesOnOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.8'

  def up
    add_concurrent_foreign_key(
      :namespaces,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:namespaces, column: :organization_id, reverse_lock_order: true)
    end
  end
end
