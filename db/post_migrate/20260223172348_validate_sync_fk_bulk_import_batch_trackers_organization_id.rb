# frozen_string_literal: true

class ValidateSyncFkBulkImportBatchTrackersOrganizationId < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_607aa73b9b'

  milestone '18.10'

  def up
    validate_foreign_key :bulk_import_batch_trackers, :organization_id, name: FK_NAME
  end

  def down
    # no-op
  end
end
