# frozen_string_literal: true

class QueueDeleteNoLongerUsedPlaceholderReferences < Gitlab::Database::Migration[2.3]
  milestone '18.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "DeleteNoLongerUsedPlaceholderReferences"
  BATCH_SIZE = 8000
  SUB_BATCH_SIZE = 300

  def up
    queue_batched_background_migration(
      MIGRATION,
      :import_source_user_placeholder_references,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :import_source_user_placeholder_references, :id, [])
  end
end
