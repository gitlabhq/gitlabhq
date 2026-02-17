# frozen_string_literal: true

class ValidateFkBulkImportBatchTrackersNamespaceId < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_7d065b6ad0'

  milestone '18.9'

  # TODO: FK to be validated synchronously in a follow-up migration after async validation completes
  def up
    prepare_async_foreign_key_validation :bulk_import_batch_trackers, :namespace_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :bulk_import_batch_trackers, :namespace_id, name: FK_NAME
  end
end
