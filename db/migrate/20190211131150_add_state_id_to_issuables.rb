class AddStateIdToIssuables < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers
  #include AfterCommitQueue

  DOWNTIME = false
  MIGRATION = 'SyncIssuablesStateId'.freeze

  # 2019-02-12 Gitlab.com issuable numbers
  # issues count: 13587305
  # merge requests count: 18925274
  # Using this 50000 as batch size should take around 13 hours
  # to migrate both issues and merge requests
  BATCH_SIZE = 50000
  DELAY_INTERVAL = 5.minutes.to_i

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  class MergeRequest < ActiveRecord::Base
    include EachBatch

    self.table_name = 'merge_requests'
  end

  def up
    add_column :issues, :state_id, :integer, limit: 1
    add_column :merge_requests, :state_id, :integer, limit: 1

    # Is this safe?
    # Added to avoid an warning about jobs running inside transactions.
    # Since we only add a column this should be ok
    Sidekiq::Worker.skipping_transaction_check do
      queue_background_migration_jobs_by_range_at_intervals(Issue.where(state_id: nil), MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
      queue_background_migration_jobs_by_range_at_intervals(MergeRequest.where(state_id: nil), MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
    end
  end

  def down
    remove_column :issues, :state_id
    remove_column :merge_requests, :state_id
  end
end
