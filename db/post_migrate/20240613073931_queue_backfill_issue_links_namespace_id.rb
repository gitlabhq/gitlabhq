# frozen_string_literal: true

class QueueBackfillIssueLinksNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillIssueLinksNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issue_links,
      :id,
      :namespace_id,
      :issues,
      :namespace_id,
      :source_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      :issue_links,
      :id,
      [
        :namespace_id,
        :issues,
        :namespace_id,
        :source_id
      ]
    )
  end
end
