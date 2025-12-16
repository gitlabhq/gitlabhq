# frozen_string_literal: true

class AddConcurrentIndexToShardingKeyColumnsOnBulkImportBatchTrackers < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = 'bulk_import_batch_trackers'

  ORGANIZATION_INDEX = 'idx_bulk_import_batch_trackers_on_organization_id'
  NAMESPACE_INDEX = 'idx_bulk_import_batch_trackers_on_namespace_id'
  PROJECT_INDEX = 'idx_bulk_import_batch_trackers_on_project_id'

  def up
    add_concurrent_index TABLE_NAME, :organization_id, name: ORGANIZATION_INDEX
    add_concurrent_index TABLE_NAME, :namespace_id, name: NAMESPACE_INDEX
    add_concurrent_index TABLE_NAME, :project_id, name: PROJECT_INDEX
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, PROJECT_INDEX
    remove_concurrent_index_by_name TABLE_NAME, NAMESPACE_INDEX
    remove_concurrent_index_by_name TABLE_NAME, ORGANIZATION_INDEX
  end
end
