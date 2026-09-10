# frozen_string_literal: true

class QueueBackfillImportSourceUsersReassignmentExpiresAt < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'BackfillImportSourceUsersReassignmentExpiresAt'
  TABLE_NAME = :import_source_users
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 200

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, :id, [])
  end
end
