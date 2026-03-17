# frozen_string_literal: true

class ExtractDeletionScheduledAtFromStateMetadata < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  BATCH_SIZE = 300

  def up
    loop do
      rows_updated = execute(<<~SQL).cmd_tuples
        UPDATE namespace_details
        SET
          deletion_scheduled_at = (state_metadata->>'deletion_scheduled_at')::timestamptz,
          state_metadata = state_metadata - 'deletion_scheduled_at'
        WHERE namespace_id IN (
          SELECT namespace_id
          FROM namespace_details
          WHERE state_metadata ? 'deletion_scheduled_at'
            AND deletion_scheduled_at IS NULL
          LIMIT #{BATCH_SIZE}
        )
      SQL

      Gitlab::AppLogger.info("ExtractDeletionScheduledAtFromStateMetadata: updated #{rows_updated} rows")
      break if rows_updated == 0
    end

    Gitlab::AppLogger.info("Completed migration: ExtractDeletionScheduledAtFromStateMetadata")
  end

  def down
    loop do
      rows_updated = execute(<<~SQL).cmd_tuples
        UPDATE namespace_details
        SET
          state_metadata = state_metadata || jsonb_build_object(
            'deletion_scheduled_at',
            to_char(deletion_scheduled_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ),
          deletion_scheduled_at = NULL
        WHERE namespace_id IN (
          SELECT namespace_id
          FROM namespace_details
          WHERE deletion_scheduled_at IS NOT NULL
            AND NOT state_metadata ? 'deletion_scheduled_at'
          LIMIT #{BATCH_SIZE}
        )
      SQL

      Gitlab::AppLogger.info("ExtractDeletionScheduledAtFromStateMetadata rollback: updated #{rows_updated} rows")
      break if rows_updated == 0
    end

    Gitlab::AppLogger.info("Completed rollback: ExtractDeletionScheduledAtFromStateMetadata")
  end
end
