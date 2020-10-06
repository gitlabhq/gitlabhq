# frozen_string_literal: true

class ScheduleSyncBlockingIssuesCount < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 50
  DELAY_INTERVAL = 120.seconds.to_i
  MIGRATION = 'SyncBlockingIssuesCount'.freeze

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  def up
    return unless Gitlab.ee?

    blocking_issues_ids = <<-SQL
      SELECT issue_links.source_id AS blocking_issue_id
      FROM issue_links
      INNER JOIN issues ON issue_links.source_id = issues.id
      WHERE issue_links.link_type = 1
      AND issues.state_id = 1
      AND issues.blocking_issues_count = 0
      UNION
      SELECT issue_links.target_id AS blocking_issue_id
      FROM issue_links
      INNER JOIN issues ON issue_links.target_id = issues.id
      WHERE issue_links.link_type = 2
      AND issues.state_id = 1
      AND issues.blocking_issues_count = 0
    SQL

    relation =
      Issue.where("id IN(#{blocking_issues_ids})") # rubocop:disable GitlabSecurity/SqlInjection

    queue_background_migration_jobs_by_range_at_intervals(
      relation,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
