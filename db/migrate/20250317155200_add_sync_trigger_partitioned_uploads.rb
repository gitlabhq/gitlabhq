# frozen_string_literal: true

class AddSyncTriggerPartitionedUploads < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.11'

  disable_ddl_transaction!

  def up
    current_primary_key = Array.wrap(connection.primary_key(:uploads))
    create_trigger_to_sync_tables(:uploads, :uploads_9ba88c4165, current_primary_key)
  end

  def down
    # rubocop:disable Migration/WithLockRetriesDisallowedMethod -- copied from helpers
    with_lock_retries do
      drop_sync_trigger(:uploads)
    end
    # rubocop:enable Migration/WithLockRetriesDisallowedMethod
  end
end
