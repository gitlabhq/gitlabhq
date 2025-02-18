# frozen_string_literal: true

class IndexBulkImportFailuresOnOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_import_failures_on_organization_id'

  def up
    add_concurrent_index :bulk_import_failures, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_failures, INDEX_NAME
  end
end
