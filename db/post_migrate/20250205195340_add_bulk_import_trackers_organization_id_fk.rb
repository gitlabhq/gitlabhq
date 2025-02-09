# frozen_string_literal: true

class AddBulkImportTrackersOrganizationIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :bulk_import_trackers, :organizations, column: :organization_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :bulk_import_trackers, column: :organization_id
    end
  end
end
