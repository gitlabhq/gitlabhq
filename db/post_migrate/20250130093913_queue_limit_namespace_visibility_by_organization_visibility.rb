# frozen_string_literal: true

# rubocop:disable BackgroundMigration/DictionaryFile -- Batched background migration was re-enqueued by
# 20250217075357_requeue_limit_namespace_visibility_by_organization_visibility.rb
class QueueLimitNamespaceVisibilityByOrganizationVisibility < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "LimitNamespaceVisibilityByOrganizationVisibility"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 3_000
  SUB_BATCH_SIZE = 300

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
# rubocop:enable BackgroundMigration/DictionaryFile
