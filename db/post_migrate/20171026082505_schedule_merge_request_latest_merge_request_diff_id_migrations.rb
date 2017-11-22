class ScheduleMergeRequestLatestMergeRequestDiffIdMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 50_000
  MIGRATION = 'PopulateMergeRequestsLatestMergeRequestDiffId'

  disable_ddl_transaction!

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    include ::EachBatch
  end

  # On GitLab.com, we saw that we generated about 500,000 dead tuples over 5 minutes.
  # To keep replication lag from ballooning, we'll aim for 50,000 updates over 5 minutes.
  #
  # Assuming that there are 5 million rows affected (which is more than on
  # GitLab.com), and that each batch of 50,000 rows takes up to 5 minutes, then
  # we can migrate all the rows in 8.5 hours.
  def up
    MergeRequest.where(latest_merge_request_diff_id: nil).each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 5.minutes, MIGRATION, range)
    end
  end
end
