# frozen_string_literal: true

class QueueCreateMissingTerraformModuleMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'CreateMissingTerraformModuleMetadata'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 200

  def up
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
