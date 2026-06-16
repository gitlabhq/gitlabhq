# frozen_string_literal: true

class RenameDeletionScheduledAtToSoftDeletedAtInOrganizationDetails < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  disable_ddl_transaction!

  def up
    rename_column_concurrently :organization_details, :deletion_scheduled_at, :soft_deleted_at,
      batch_column_name: :organization_id
  end

  def down
    undo_rename_column_concurrently :organization_details, :deletion_scheduled_at, :soft_deleted_at
  end
end
