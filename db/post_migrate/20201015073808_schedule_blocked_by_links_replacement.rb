# frozen_string_literal: true

class ScheduleBlockedByLinksReplacement < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 2.minutes
  # at the time of writing there were 47600 blocked_by issues:
  # estimated time is 48 batches * 2 minutes -> 100 minutes
  BATCH_SIZE = 1000
  MIGRATION = 'ReplaceBlockedByLinks'

  disable_ddl_transaction!

  class IssueLink < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issue_links'
  end

  def up
    relation = IssueLink.where(link_type: 2)

    queue_background_migration_jobs_by_range_at_intervals(
      relation, MIGRATION, INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
  end
end
