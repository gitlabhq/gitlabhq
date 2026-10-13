# frozen_string_literal: true

class QueueBackfillCiNamespaceMirrorsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiNamespaceMirrorsOrganizationId"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_namespace_mirrors,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_namespace_mirrors, :id, [])
  end
end
