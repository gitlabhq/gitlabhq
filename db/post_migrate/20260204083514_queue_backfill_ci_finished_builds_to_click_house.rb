# frozen_string_literal: true

class QueueBackfillCiFinishedBuildsToClickHouse < Gitlab::Database::Migration[2.3]
  milestone "18.10"

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = "BackfillCiFinishedBuildsToClickHouse"
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 1000
  BACKFILL_PERIOD = 180.days

  FINISHED_STATUSES = %w[success failed canceled].freeze

  def up
    min_id = find_min_id_for_backfill_period

    if min_id.nil?
      say "Migration skipped: No valid records found to start backfilling"
      return
    end

    say "Starting backfill from id: #{min_id}"

    queue_batched_background_migration(
      MIGRATION,
      :p_ci_builds,
      :id,
      batch_min_value: min_id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :p_ci_builds, :id, [])
  end

  private

  # Finds the starting id for backfill by querying each finished status separately
  # and taking the minimum id from the results.
  #
  # Uses index: p_ci_builds_status_created_at_project_id_idx (status, created_at, project_id)
  # WHERE type = 'Ci::Build'
  #
  # Each query orders by created_at to leverage the index ordering.
  # Running 3 separate queries (one per status) is more efficient than a single query
  # with IN clause because each query can use the index directly.
  def find_min_id_for_backfill_period
    min_ids = FINISHED_STATUSES.filter_map do |status|
      find_min_id_for_status(status)
    end

    min_ids.min
  end

  def find_min_id_for_status(status)
    backfill_start_date = connection.quote(BACKFILL_PERIOD.ago.beginning_of_day)
    quoted_status = connection.quote(status)

    execute(<<~SQL).first&.fetch("id", nil)
      SELECT id
      FROM p_ci_builds
      WHERE type = 'Ci::Build'
        AND status = #{quoted_status}
        AND created_at >= #{backfill_start_date}
      ORDER BY created_at ASC
      LIMIT 1
    SQL
  end
end
