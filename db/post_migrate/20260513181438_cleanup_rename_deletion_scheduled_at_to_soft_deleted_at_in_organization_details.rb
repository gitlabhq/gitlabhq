# frozen_string_literal: true

class CleanupRenameDeletionScheduledAtToSoftDeletedAtInOrganizationDetails < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :organization_details, :deletion_scheduled_at, :soft_deleted_at
  end

  def down
    undo_cleanup_concurrent_column_rename :organization_details, :deletion_scheduled_at, :soft_deleted_at,
      batch_column_name: :organization_id
  end
end
