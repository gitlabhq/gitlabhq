# frozen_string_literal: true

class ScheduleSyncIssuablesStateId < ActiveRecord::Migration[5.0]
  # This migration schedules the sync of state_id for issues and merge requests
  # which are converting the state column from string to integer.
  # For more information check: https://gitlab.com/gitlab-org/gitlab-foss/issues/51789

  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # 2019-02-12 gitlab.com issuable numbers
  # issues count: 13587305
  # merge requests count: 18925274
  #
  # Using 5000 as batch size and 115 seconds interval will give:
  # 2718 jobs for issues - taking ~86 hours
  # 3786 jobs for merge requests - taking ~120 hours
  #
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 120.seconds.to_i
  ISSUES_MIGRATION = 'SyncIssuesStateId'
  MERGE_REQUESTS_MIGRATION = 'SyncMergeRequestsStateId'

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Issue.all,
      ISSUES_MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )

    queue_background_migration_jobs_by_range_at_intervals(
      MergeRequest.all,
      MERGE_REQUESTS_MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # No op
  end
end
