# frozen_string_literal: true

class QueueBackfillOccurrenceIdToExternalIssueLinks < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  MIGRATION = "BackfillOccurrenceIdToExternalIssueLinks"

  def up
    queue_batched_background_migration(
      MIGRATION,
      :vulnerability_external_issue_links,
      :id
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :vulnerability_external_issue_links, :id, [])
  end
end
