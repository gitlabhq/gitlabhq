# frozen_string_literal: true

class QueueBackfillDesignUserMentionsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillDesignUserMentionsNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :design_user_mentions,
      :id,
      :namespace_id,
      :design_management_designs,
      :namespace_id,
      :design_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :design_user_mentions,
      :id,
      [
        :namespace_id,
        :design_management_designs,
        :namespace_id,
        :design_id
      ]
    )
  end
end
