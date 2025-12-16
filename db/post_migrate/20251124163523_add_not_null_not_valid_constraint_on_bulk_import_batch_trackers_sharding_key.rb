# frozen_string_literal: true

class AddNotNullNotValidConstraintOnBulkImportBatchTrackersShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  TABLE_NAME = 'bulk_import_batch_trackers'

  def up
    add_multi_column_not_null_constraint(
      TABLE_NAME,
      :organization_id, :namespace_id, :project_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(
      TABLE_NAME,
      :organization_id, :namespace_id, :project_id
    )
  end
end
