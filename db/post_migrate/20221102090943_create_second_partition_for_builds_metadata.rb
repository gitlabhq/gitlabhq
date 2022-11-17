# frozen_string_literal: true

class CreateSecondPartitionForBuildsMetadata < Gitlab::Database::Migration[2.0]
  TABLE_NAME = 'p_ci_builds_metadata'
  BUILDS_TABLE = 'ci_builds'
  NEXT_PARTITION_ID = 101
  PARTITION_NAME = 'gitlab_partitions_dynamic.ci_builds_metadata_101'

  disable_ddl_transaction!

  def up
    return unless Gitlab.com?

    with_lock_retries(**lock_args) do
      connection.execute(<<~SQL)
        LOCK TABLE #{BUILDS_TABLE} IN SHARE UPDATE EXCLUSIVE MODE;
        LOCK TABLE ONLY #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE;
      SQL

      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{PARTITION_NAME}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES IN (#{NEXT_PARTITION_ID});
      SQL
    end
  end

  def down
    return unless Gitlab.com?
    return unless table_exists?(PARTITION_NAME)

    with_lock_retries(**lock_args) do
      connection.execute(<<~SQL)
        LOCK TABLE #{BUILDS_TABLE}, #{TABLE_NAME}, #{PARTITION_NAME} IN ACCESS EXCLUSIVE MODE;
      SQL

      connection.execute(<<~SQL)
        ALTER TABLE #{TABLE_NAME} DETACH PARTITION #{PARTITION_NAME};
      SQL

      connection.execute(<<~SQL)
        DROP TABLE IF EXISTS #{PARTITION_NAME} CASCADE;
      SQL
    end
  end

  private

  def lock_args
    {
      raise_on_exhaustion: true,
      timing_configuration: lock_timing_configuration
    }
  end

  def lock_timing_configuration
    iterations = Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION
    aggressive_iterations = Array.new(5) { [10.seconds, 1.minute] }

    iterations + aggressive_iterations
  end
end
