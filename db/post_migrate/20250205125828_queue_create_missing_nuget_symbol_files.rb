# frozen_string_literal: true

class QueueCreateMissingNugetSymbolFiles < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'CreateMissingNugetSymbolFiles'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    return unless Gitlab.com?

    queue_batched_background_migration(
      MIGRATION,
      :packages_packages,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_packages, :id, [])
  end
end
