# frozen_string_literal: true

class AddNotNullNotValidConstraintOnBulkImportTrackersShardingKey < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    add_multi_column_not_null_constraint(
      :bulk_import_trackers,
      :namespace_id, :project_id, :organization_id,
      validate: false
    )
  end

  def down
    remove_multi_column_not_null_constraint(:bulk_import_trackers, :namespace_id, :project_id, :organization_id)
  end
end
