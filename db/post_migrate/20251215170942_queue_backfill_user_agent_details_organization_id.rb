# frozen_string_literal: true

class QueueBackfillUserAgentDetailsOrganizationId < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillUserAgentDetailsOrganizationId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :user_agent_details,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :user_agent_details, :id, [])
  end
end
