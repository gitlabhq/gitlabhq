# frozen_string_literal: true

class AddForeignKeyConstraintOnBulkImportExportsOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = 'bulk_import_exports'

  def up
    add_concurrent_foreign_key TABLE_NAME,
      :organizations,
      column: :organization_id,
      on_delete: :cascade,
      validate: false
  end

  def down
    remove_foreign_key_if_exists TABLE_NAME, :organizations, column: :organization_id
  end
end
