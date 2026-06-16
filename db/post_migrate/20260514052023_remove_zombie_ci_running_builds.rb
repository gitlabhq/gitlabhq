# frozen_string_literal: true

class RemoveZombieCiRunningBuilds < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  BATCH_SIZE = 500
  MAX_BATCHES = 100
  COMPLETED_STATUSES = %w[success failed canceled skipped].freeze

  def up
    Gitlab::Database::DataIsolation::ScopeHelper.without_data_isolation do
      running_builds = define_batchable_model('ci_running_builds')
      quoted_statuses = COMPLETED_STATUSES.map { |status| quote(status) }.join(', ')
      total_deleted = 0

      MAX_BATCHES.times do
        batch = running_builds.where(<<~SQL).limit(BATCH_SIZE)
          EXISTS (
            SELECT 1
            FROM p_ci_builds
            WHERE p_ci_builds.id = ci_running_builds.build_id
              AND p_ci_builds.partition_id = ci_running_builds.partition_id
              AND p_ci_builds.status IN (#{quoted_statuses})
          )
        SQL

        deleted_count = running_builds.where(id: batch.select(:id)).delete_all
        total_deleted += deleted_count
        break if deleted_count == 0
      end

      say "Deleted #{total_deleted} zombie ci_running_builds records"
    end
  end

  def down
    # no-op - zombie records cannot be restored
  end
end
