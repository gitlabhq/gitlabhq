# frozen_string_literal: true

class QueueBackfillTerraformModulesMetadataWithSemver < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillTerraformModulesMetadataWithSemver'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 5000
  SUB_BATCH_SIZE = 250
  BATCH_CLASS_NAME = 'LooseIndexScanBatchingStrategy'

  def up
    queue_batched_background_migration(
      MIGRATION,
      :packages_packages,
      :project_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      batch_class_name: BATCH_CLASS_NAME
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :packages_packages, :project_id, [])
  end
end
