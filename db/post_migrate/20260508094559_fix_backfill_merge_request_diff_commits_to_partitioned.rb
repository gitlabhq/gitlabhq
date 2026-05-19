# frozen_string_literal: true

class FixBackfillMergeRequestDiffCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  TABLE = :merge_request_diff_commits
  MIGRATION = "BackfillMergeRequestDiffCommitsToPartitioned"
  BATCH_SIZE = 500_000
  SUB_BATCH_SIZE = 10_000

  VIEW_PREFIX = 'merge_request_diff_commits_views'
  VIEW_COUNT = 4

  def up
    if Gitlab.com_except_jh?
      # PgClass.for_table returns nil for views; derive per-view estimate from the underlying table.
      per_view_count = Gitlab::Database::PgClass.for_table(TABLE)&.cardinality_estimate
                         &./(VIEW_COUNT)

      VIEW_COUNT.times do |index|
        view_name = "#{VIEW_PREFIX}_#{index + 1}"

        existing = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_configuration(:gitlab_main_org, MIGRATION, view_name, :merge_request_diff_id,
            [:merge_request_diff_commits_b5377a7a34])
          .first

        next unless existing

        attrs = { sub_batch_size: SUB_BATCH_SIZE, batch_size: BATCH_SIZE }
        attrs[:total_tuple_count] = per_view_count if per_view_count
        existing.update!(attrs)
      end
    else
      existing = Gitlab::Database::BackgroundMigration::BatchedMigration
        .for_configuration(:gitlab_main_org, MIGRATION, TABLE, :merge_request_diff_id,
          [:merge_request_diff_commits_b5377a7a34])
        .first

      return unless existing

      existing.update!(sub_batch_size: SUB_BATCH_SIZE, batch_size: BATCH_SIZE)
    end
  end

  def down
    # no-op: sub_batch_size/batch_size/total_tuple_count updates are not reverted
  end
end
