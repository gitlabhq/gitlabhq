# frozen_string_literal: true

class QueueRemoveNamespaceFromOsTypeSbomComponents < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "RemoveNamespaceFromOsTypeSbomComponents"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 2000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :sbom_components,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :sbom_components, :id, [])
  end
end
