class ScheduleMergeRequestDiffMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 2500
  MIGRATION = 'DeserializeMergeRequestDiffsAndCommits'

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  # Assuming that there are 5 million rows affected (which is more than on
  # GitLab.com), and that each batch of 2,500 rows takes up to 5 minutes, then
  # we can migrate all the rows in 7 days.
  #
  # On staging, plucking the IDs themselves takes 5 seconds.
  def up
    non_empty = 'st_commits IS NOT NULL OR st_diffs IS NOT NULL'

    MergeRequestDiff.where(non_empty).each_batch(of: BATCH_SIZE) do |relation, index|
      range = relation.pluck('MIN(id)', 'MAX(id)').first

      BackgroundMigrationWorker.perform_in(index * 5.minutes, MIGRATION, range)
    end
  end

  def down
  end
end
