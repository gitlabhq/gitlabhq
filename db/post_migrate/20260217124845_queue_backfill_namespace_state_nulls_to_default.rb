# frozen_string_literal: true

class QueueBackfillNamespaceStateNullsToDefault < Gitlab::Database::Migration[2.3]
  milestone '18.10'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillNamespaceStateNullsToDefault"
  SUB_BATCH_SIZE = 300

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
