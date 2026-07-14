# frozen_string_literal: true

class QueueBackfillExcludedMergeRequestDiffCommits < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillExcludedMergeRequestDiffCommits'

  def up
    # no-op: This migration has been requeued by RequeueBackfillExcludedMergeRequestDiffCommits
  end

  def down
    # no-op: This migration has been requeued by RequeueBackfillExcludedMergeRequestDiffCommits
  end
end
