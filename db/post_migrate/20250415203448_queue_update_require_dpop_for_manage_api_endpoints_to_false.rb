# frozen_string_literal: true

class QueueUpdateRequireDpopForManageApiEndpointsToFalse < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'UpdateRequireDpopForManageApiEndpointsToFalse'

  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  TABLE_NAME = :namespace_settings
  COLUMN_NAME = :namespace_id

  # Only numeric or time-based columns can be used to divide tables for batching so,
  # the :namespace_id is used in place of the :require_dpop_for_manage_api_endpoints column
  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      COLUMN_NAME,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, COLUMN_NAME, [])
  end
end
