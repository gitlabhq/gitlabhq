# frozen_string_literal: true

class IndexBulkImportConfigurationsOnOrganizationId < Gitlab::Database::Migration[2.2]
  milestone '17.11'
  disable_ddl_transaction!

  INDEX_NAME = 'index_bulk_import_configurations_on_organization_id'

  def up
    add_concurrent_index :bulk_import_configurations, :organization_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :bulk_import_configurations, INDEX_NAME
  end
end
