# frozen_string_literal: true

class DropForeignKeyOnBulkImportExportsOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.3'

  TABLE_NAME = 'bulk_import_exports'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :organizations, column: :organization_id
    end
  end

  def down
    add_concurrent_foreign_key TABLE_NAME,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      validate: false
  end
end
