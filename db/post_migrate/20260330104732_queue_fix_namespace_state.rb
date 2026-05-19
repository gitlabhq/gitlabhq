# frozen_string_literal: true

class QueueFixNamespaceState < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "FixNamespaceState"
  BATCH_SIZE = 3000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
