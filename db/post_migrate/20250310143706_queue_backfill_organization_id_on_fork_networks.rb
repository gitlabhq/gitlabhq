# frozen_string_literal: true

class QueueBackfillOrganizationIdOnForkNetworks < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillOrganizationIdOnForkNetworks"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :fork_networks,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :fork_networks, :id, [])
  end
end
