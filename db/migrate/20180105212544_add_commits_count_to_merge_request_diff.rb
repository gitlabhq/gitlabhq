class AddCommitsCountToMergeRequestDiff < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'AddMergeRequestDiffCommitsCount'.freeze
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 5.minutes.to_i

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    add_column :merge_request_diffs, :commits_count, :integer

    say 'Populating the MergeRequestDiff `commits_count`'

    queue_background_migration_jobs_by_range_at_intervals(MergeRequestDiff, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    remove_column :merge_request_diffs, :commits_count
  end
end
