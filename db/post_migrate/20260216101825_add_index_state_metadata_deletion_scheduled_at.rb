# frozen_string_literal: true

class AddIndexStateMetadataDeletionScheduledAt < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  TABLE_NAME = :namespace_details
  INDEX_NAME = 'tmp_idx_backfill_deletion_scheduled_at'

  def up
    add_concurrent_index TABLE_NAME, :namespace_id,
      name: INDEX_NAME,
      where: "state_metadata ? 'deletion_scheduled_at' AND deletion_scheduled_at IS NULL"
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
