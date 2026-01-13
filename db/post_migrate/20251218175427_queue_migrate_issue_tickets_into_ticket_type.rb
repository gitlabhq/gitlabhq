# frozen_string_literal: true

class QueueMigrateIssueTicketsIntoTicketType < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "MigrateIssueTicketsIntoTicketType"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 25

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
