# frozen_string_literal: true

class ScheduleSyncIssuablesStateIdWhereNil < ActiveRecord::Migration[5.1]
  # Issues and MergeRequests imported by GitHub are being created with
  # state_id = null, this fixes them.
  #
  # Part of a bigger plan: https://gitlab.com/gitlab-org/gitlab-foss/issues/51789

  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # 2019-05-02 gitlab.com issuable numbers
  # issues with state_id nil: ~40000
  # merge requests with state_id nil: ~200000
  #
  # Using 5000 as batch size and 120 seconds interval will create:
  # ~8 jobs for issues - taking ~16 minutes
  # ~40 jobs for merge requests - taking ~1.34 hours
  #
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 120.seconds.to_i
  ISSUES_MIGRATION = 'SyncIssuesStateId'.freeze
  MERGE_REQUESTS_MIGRATION = 'SyncMergeRequestsStateId'.freeze

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
      Issue.where(state_id: nil),
      ISSUES_MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )

    queue_background_migration_jobs_by_range_at_intervals(
      MergeRequest.where(state_id: nil),
      MERGE_REQUESTS_MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )

    # Remove temporary indexes added on "AddTemporaryIndexesToStateId"
    remove_concurrent_index_by_name(:issues, "idx_on_issues_where_state_id_is_null")
    remove_concurrent_index_by_name(:merge_requests, "idx_on_merge_requests_where_state_id_is_null")
  end

  def down
    # No op
  end
end
