# frozen_string_literal: true

class ValidateFkBulkImportBatchTrackersProjectId < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_4cd59701d0'

  milestone '18.9'

  # TODO: FK to be validated synchronously in a follow-up migration after async validation completes
  def up
    prepare_async_foreign_key_validation :bulk_import_batch_trackers, :project_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :bulk_import_batch_trackers, :project_id, name: FK_NAME
  end
end
