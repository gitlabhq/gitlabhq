# frozen_string_literal: true

class UpdateBackfillMergeRequestDiffCommitsToPartitioned < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillMergeRequestDiffCommitsToPartitioned"
  MAX_BATCH_SIZE = 2_000_000

  VIEW_PREFIX = 'merge_request_diff_commits_views'
  VIEW_COUNT = 4

  def up
    # MAX_BATCH_SIZE was capped only for Gitlab.com
    return unless Gitlab.com_except_jh?

    VIEW_COUNT.times do |index|
      view_name = "#{VIEW_PREFIX}_#{index + 1}"

      existing_migration =
        Gitlab::Database::BackgroundMigration::BatchedMigration
           .for_configuration(:gitlab_main_org, MIGRATION, view_name, :merge_request_diff_id,
             [:merge_request_diff_commits_b5377a7a34])
           .first

      next unless existing_migration

      existing_migration.update!({ max_batch_size: MAX_BATCH_SIZE })
    end
  end

  def down
    # no-op: max_batch_size updates are not reverted
  end
end
