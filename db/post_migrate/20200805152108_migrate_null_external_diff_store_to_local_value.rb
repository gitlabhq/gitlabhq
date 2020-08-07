# frozen_string_literal: true

class MigrateNullExternalDiffStoreToLocalValue < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  JOB_INTERVAL = 2.minutes + 5.seconds
  BATCH_SIZE = 5_000
  MIGRATION = 'SetNullExternalDiffStoreToLocalValue'

  disable_ddl_transaction!

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    include ::EachBatch
  end

  def up
    # On GitLab.com, 19M of 93M rows have NULL external_diff_store.
    #
    # With batches of 5000 and a background migration job interval of 2m 5s,
    # 3.8K jobs are scheduled over 5.5 days.
    #
    # The index `index_merge_request_diffs_external_diff_store_is_null` is
    # expected to be used here and in the jobs.
    #
    # queue_background_migration_jobs_by_range_at_intervals is not used because
    # it would enqueue 18.6K jobs and we have an index for getting these ranges.
    MergeRequestDiff.where(external_diff_store: nil).each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql("MIN(id)"), Arel.sql("MAX(id)")).first
      delay = index * JOB_INTERVAL

      migrate_in(delay.seconds, MIGRATION, [*range])
    end
  end

  def down
    # noop
  end
end
