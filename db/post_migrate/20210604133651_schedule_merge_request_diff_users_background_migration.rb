# frozen_string_literal: true

class ScheduleMergeRequestDiffUsersBackgroundMigration < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # The number of rows to process in a single migration job.
  #
  # The minimum interval for background migrations is two minutes. On staging we
  # observed we can process roughly 20 000 rows in a minute. Based on the total
  # number of rows on staging, this translates to a total processing time of
  # roughly 14 days.
  #
  # By using a batch size of 40 000, we maintain a rate of roughly 20 000 rows
  # per minute, hopefully keeping the total migration time under two weeks;
  # instead of four weeks.
  BATCH_SIZE = 40_000

  MIGRATION_NAME = 'MigrateMergeRequestDiffCommitUsers'

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'
  end

  def up
    start = MergeRequestDiff.minimum(:id).to_i
    max = MergeRequestDiff.maximum(:id).to_i
    delay = BackgroundMigrationWorker.minimum_interval

    # The table merge_request_diff_commits contains _a lot_ of rows (roughly 400
    # 000 000 on staging). Iterating a table that large to determine job ranges
    # would take a while.
    #
    # To avoid that overhead, we simply schedule fixed ranges according to the
    # minimum and maximum IDs. The background migration in turn only processes
    # rows that actually exist.
    while start < max
      stop = start + BATCH_SIZE

      migrate_in(delay, MIGRATION_NAME, [start, stop])

      Gitlab::Database::BackgroundMigrationJob
        .create!(class_name: MIGRATION_NAME, arguments: [start, stop])

      delay += BackgroundMigrationWorker.minimum_interval
      start += BATCH_SIZE
    end
  end

  def down
    # no-op
  end
end
