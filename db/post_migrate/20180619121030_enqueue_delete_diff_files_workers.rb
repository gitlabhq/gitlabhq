class EnqueueDeleteDiffFilesWorkers < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class MergeRequestDiff < ActiveRecord::Base
    self.table_name = 'merge_request_diffs'

    belongs_to :merge_request

    include EachBatch
  end

  DOWNTIME = false
  BATCH_SIZE = 1000
  MIGRATION = 'DeleteDiffFiles'
  DELAY_INTERVAL = 10.minutes
  TMP_INDEX = 'tmp_partial_diff_id_with_files_index'.freeze

  disable_ddl_transaction!

  def up
    # We add temporary index, to make iteration over batches more performant.
    # Conditional here is to avoid the need of doing that in a separate
    # migration file to make this operation idempotent.
    #
    unless index_exists_by_name?(:merge_request_diffs, TMP_INDEX)
      add_concurrent_index(:merge_request_diffs, :id, where: "(state NOT IN ('without_files', 'empty'))", name: TMP_INDEX)
    end


    diffs_with_files = MergeRequestDiff.where.not(state: ['without_files', 'empty'])

    # explain (analyze, buffers) example for the iteration:
    #
    # Index Only Scan using tmp_index_20013 on merge_request_diffs  (cost=0.43..1630.19 rows=60567 width=4) (actual time=0.047..9.572 rows=56976 loops=1)
    #   Index Cond: ((id >= 764586) AND (id < 835298))
    #   Heap Fetches: 8
    #   Buffers: shared hit=18188
    # Planning time: 0.752 ms
    # Execution time: 12.430 ms
    #
    diffs_with_files.each_batch(of: BATCH_SIZE) do |relation, outer_index|
      # We slice the batches in groups of 5 and schedule each group of 5 at
      # once. This should make writings on Redis go 5x faster.
      job_batches = relation.pluck(:id).in_groups_of(5, false).map do |ids|
        ids.map { |id| [MIGRATION, [id]] }
      end

      job_batches.each_with_index do |jobs, inner_index|
        # This will give some space between batches of workers.
        interval = DELAY_INTERVAL * outer_index + inner_index.minutes

        # A single `merge_request_diff` can be associated with way too many
        # `merge_request_diff_files`. It's better to avoid scheduling big
        # batches and go with 5 at a time.
        #
        BackgroundMigrationWorker.bulk_perform_in(interval, jobs)
      end
    end

    # We remove temporary index, because it is not required during standard
    # operations and runtime.
    #
    remove_concurrent_index_by_name(:merge_request_diffs, TMP_INDEX)
  end

  def down
    if index_exists_by_name?(:merge_request_diffs, TMP_INDEX)
      remove_concurrent_index_by_name(:merge_request_diffs, TMP_INDEX)
    end
  end
end
