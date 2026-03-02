# frozen_string_literal: true

class ValidateSyncFkBulkImportBatchTrackersProjectId < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_4cd59701d0'

  milestone '18.10'

  def up
    validate_foreign_key :bulk_import_batch_trackers, :project_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
