# frozen_string_literal: true

class QueueBackfillNamespaceTraversalIdsOnIssues < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillNamespaceTraversalIdsOnIssues"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  def up
    # no-op: This migration has been requeued by RequeueBackfillNamespaceTraversalIdsOnIssues
  end

  def down
    # no-op: This migration has been requeued by RequeueBackfillNamespaceTraversalIdsOnIssues
  end
end
