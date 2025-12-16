# frozen_string_literal: true

class AddShardingKeyColumnsToBulkImportBatchTrackers < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = 'bulk_import_batch_trackers'

  def up
    add_column TABLE_NAME, :organization_id, :bigint
    add_column TABLE_NAME, :namespace_id, :bigint
    add_column TABLE_NAME, :project_id, :bigint
  end

  def down
    remove_column TABLE_NAME, :project_id
    remove_column TABLE_NAME, :namespace_id
    remove_column TABLE_NAME, :organization_id
  end
end
