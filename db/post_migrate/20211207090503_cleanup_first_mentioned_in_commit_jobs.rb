# frozen_string_literal: true

class CleanupFirstMentionedInCommitJobs < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'FixFirstMentionedInCommitAt'
  INDEX_NAME = 'index_issue_metrics_first_mentioned_in_commit'

  def up
    finalize_background_migration(MIGRATION)

    remove_concurrent_index_by_name :issue_metrics, name: INDEX_NAME
  end

  def down
    # Handles reported schema inconsistencies (column with or without timezone)
    # We did the same in db/post_migrate/20211004110500_add_temporary_index_to_issue_metrics.rb
    condition = Gitlab::BackgroundMigration::FixFirstMentionedInCommitAt::TmpIssueMetrics
      .first_mentioned_in_commit_at_condition
    add_concurrent_index :issue_metrics, :issue_id, where: condition, name: INDEX_NAME
  end
end
