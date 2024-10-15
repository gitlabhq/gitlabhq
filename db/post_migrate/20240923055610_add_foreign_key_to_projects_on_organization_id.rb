# frozen_string_literal: true

class AddForeignKeyToProjectsOnOrganizationId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    add_concurrent_foreign_key(
      :projects,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(:projects, column: :organization_id)
    end
  end
end
