class AddStateIdToIssuables < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'SyncIssuablesStateId'.freeze

  # TODO - find out how many issues and merge requests in production
  # to adapt the batch size and delay interval
  # Keep in mind that the migration will be scheduled for issues and merge requests.
  BATCH_SIZE = 5000
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

    queue_background_migration_jobs_by_range_at_intervals(Issue.where(state_id: nil), MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
    queue_background_migration_jobs_by_range_at_intervals(MergeRequest.where(state_id: nil), MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    remove_column :issues, :state_id
    remove_column :merge_requests, :state_id
  end
end
