# frozen_string_literal: true

class ValidateSyncFkBulkImportBatchTrackersNamespaceId < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_7d065b6ad0'

  milestone '18.10'

  def up
    validate_foreign_key :bulk_import_batch_trackers, :namespace_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
