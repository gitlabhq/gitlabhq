# frozen_string_literal: true

class EnsureMinimumPauseMsInBatchedBackgroundMigrationJobs < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  MINIMUM_PAUSE_MS = 100
  TABLE_NAME = 'batched_background_migration_jobs'

  def up
    execute(<<~SQL)
      UPDATE #{TABLE_NAME}
      SET pause_ms = #{MINIMUM_PAUSE_MS}
      WHERE pause_ms < #{MINIMUM_PAUSE_MS};
    SQL
  end

  def down
    # no-op
  end
end
