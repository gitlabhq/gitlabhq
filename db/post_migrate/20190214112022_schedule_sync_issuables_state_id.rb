# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ScheduleSyncIssuablesStateId < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # 2019-02-12 Gitlab.com issuable numbers
  # issues count: 13587305
  # merge requests count: 18925274
  # Using this 25000 as batch size should take around 26 hours
  # to migrate both issues and merge requests
  BATCH_SIZE = 25000
  DELAY_INTERVAL = 5.minutes.to_i
  ISSUE_MIGRATION = 'SyncIssuesStateId'.freeze
  MERGE_REQUEST_MIGRATION = 'SyncMergeRequestsStateId'.freeze

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    Sidekiq::Worker.skipping_transaction_check do
      queue_background_migration_jobs_by_range_at_intervals(Issue.where(state_id: nil), ISSUE_MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
      queue_background_migration_jobs_by_range_at_intervals(MergeRequest.where(state_id: nil), MERGE_REQUEST_MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
    end
  end

  def down
    # No op
  end
end
