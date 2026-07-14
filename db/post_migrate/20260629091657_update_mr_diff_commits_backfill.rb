# frozen_string_literal: true

class UpdateMrDiffCommitsBackfill < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION   = "BackfillMergeRequestDiffCommitsToPartitioned"
  VIEW_PREFIX = 'merge_request_diff_commits_views'

  # Extends view 4 migration's max_cursor to cover diffs created after the migration was
  # originally queued, up to the point where the sync trigger takes over.
  # This migration is only running on Gitlab.com
  def up
    return unless Gitlab.com_except_jh?

    view4 = Gitlab::Database::BackgroundMigration::BatchedMigration
              .for_configuration(
                :gitlab_main_org, MIGRATION, "#{VIEW_PREFIX}_4",
                :merge_request_diff_id, [:merge_request_diff_commits_b5377a7a34]
              ).first
    return unless view4

    cursor = current_table_max_cursor
    return unless cursor

    view4.update!(max_cursor: cursor)
  end

  def down
    # no-op: cursor modifications and new BBM records cannot be cleanly reversed
    # mid-flight without risk of introducing data gaps or double-processing.
  end

  private

  # Returns [max_diff_id, max_relative_order] from the table, or nil if the table is empty.
  def current_table_max_cursor
    max_diff_id, max_order = define_batchable_model(:merge_request_diff_commits)
                               .order(merge_request_diff_id: :desc, relative_order: :desc)
                               .pick(:merge_request_diff_id, :relative_order)
    return unless max_diff_id

    [max_diff_id, max_order || 0]
  end
end
