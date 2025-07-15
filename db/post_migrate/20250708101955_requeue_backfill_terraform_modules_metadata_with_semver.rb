# frozen_string_literal: true

class RequeueBackfillTerraformModulesMetadataWithSemver < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillTerraformModulesMetadataWithSemver'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 500

  def up
    # Clear previous background migration execution from QueueBackfillTerraformModulesMetadataWithSemver
    delete_batched_background_migration(MIGRATION, :packages_packages, :project_id, [])

    queue_batched_background_migration(
      MIGRATION,
      :packages_packages,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_packages, :id, [])
  end
end
