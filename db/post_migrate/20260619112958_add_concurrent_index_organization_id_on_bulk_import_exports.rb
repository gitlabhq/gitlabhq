# frozen_string_literal: true

class AddConcurrentIndexOrganizationIdOnBulkImportExports < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = 'bulk_import_exports'
  INDEX_NAME = 'idx_bulk_import_exports_on_organization_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
