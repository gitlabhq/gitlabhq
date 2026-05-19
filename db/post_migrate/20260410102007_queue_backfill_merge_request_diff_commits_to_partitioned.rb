# frozen_string_literal: true

class QueueBackfillMergeRequestDiffCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  TABLE = :merge_request_diff_commits
  MIGRATION = "BackfillMergeRequestDiffCommitsToPartitioned"
  VIEWS_STRATEGY = 'BackfillMergeRequestDiffCommitsToPartitionedBatchingStrategy'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000
  SUB_BATCH_SIZE = 1000
  # Cap batch size at 1.5M to prevent optimizer runaway when batches skip rows due to excluded_merge_requests filter
  MAX_BATCH_SIZE = 1_500_000

  VIEW_PREFIX = 'merge_request_diff_commits_views'

  # Must match VIEW_LOWER_BOUNDS in CreateMergeRequestDiffCommitsViews
  VIEW_LOWER_BOUNDS = [
    0,
    405_423_843,
    1_010_436_901,
    1_224_788_900
  ].freeze

  def up
    if Gitlab.com_except_jh?
      # GitLab.com: Use parallelized approach with views
      queue_migrations_for_views
    else
      queue_simple_migration
    end
  end

  def down
    if Gitlab.com_except_jh?
      VIEW_LOWER_BOUNDS.each_with_index do |_, index|
        delete_batched_background_migration(
          MIGRATION,
          "#{VIEW_PREFIX}_#{index + 1}",
          :merge_request_diff_id,
          [:merge_request_diff_commits_b5377a7a34]
        )
      end
    else
      delete_batched_background_migration(
        MIGRATION,
        TABLE,
        :merge_request_diff_id,
        [:merge_request_diff_commits_b5377a7a34]
      )
    end
  end

  private

  def queue_migrations_for_views
    VIEW_LOWER_BOUNDS.each_with_index do |lower, index|
      upper = VIEW_LOWER_BOUNDS[index + 1]

      # For views 1-3, max_cursor uses relative_order 0. This is safe because each view
      # filters rows with diff_id < upper, so no row with diff_id = upper exists in the
      # view - the batching will never reach that cursor value. The composite cursor
      # (merge_request_diff_id, relative_order) is still fully used for iteration within
      # each job; only the terminal condition is affected here.
      # For the last view (upper is nil), the view has no upper bound so we must query
      # the actual max to give the batching an accurate stopping point.
      max_cursor = upper ? [upper, 0] : max_cursor_from_table

      queue_migration("#{VIEW_PREFIX}_#{index + 1}", min_cursor: [lower, 0], max_cursor: max_cursor)
    end
  end

  def queue_simple_migration
    queue_batched_background_migration(
      MIGRATION,
      TABLE,
      :merge_request_diff_id,
      :merge_request_diff_commits_b5377a7a34,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      min_cursor: [0, 0],
      max_cursor: max_cursor_from_table
    )
  end

  def queue_migration(table_name, min_cursor:, max_cursor:)
    queue_batched_background_migration(
      MIGRATION,
      table_name,
      :merge_request_diff_id,
      :merge_request_diff_commits_b5377a7a34,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      batch_class_name: VIEWS_STRATEGY,
      min_cursor: min_cursor,
      max_cursor: max_cursor
    )
  end

  # Returns [max_diff_id, max_relative_order] from the table.
  def max_cursor_from_table
    max_diff_id, max_order = define_batchable_model(TABLE)
                               .order(merge_request_diff_id: :desc, relative_order: :desc)
                               .pick(:merge_request_diff_id, :relative_order)
    [max_diff_id || 0, max_order || 0]
  end

  # Workaround to allow a single migration to enqueue multiple background migrations
  # Only needed for GitLab.com parallelization path
  def assign_attributes_safely(migration, max_batch_size, batch_table_name, gitlab_schema, _queued_migration_version)
    super(migration, max_batch_size, batch_table_name, gitlab_schema, nil)
  end
end
