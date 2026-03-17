# frozen_string_literal: true

class ValidateBulkImportBatchTrackersShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_13004cd9a8'

  milestone '18.10'

  def up
    validate_multi_column_not_null_constraint :bulk_import_batch_trackers,
      :organization_id, :namespace_id, :project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
