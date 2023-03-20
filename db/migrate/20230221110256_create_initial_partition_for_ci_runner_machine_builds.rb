# frozen_string_literal: true

class CreateInitialPartitionForCiRunnerMachineBuilds < Gitlab::Database::Migration[2.1]
  PARTITION_NAME = 'gitlab_partitions_dynamic.ci_runner_machine_builds_100'
  TABLE_NAME = 'p_ci_runner_machine_builds'
  FIRST_PARTITION = 100
  BUILDS_TABLE = 'ci_builds'

  disable_ddl_transaction!

  def up
    with_lock_retries(**lock_args) do
      connection.execute(<<~SQL)
        LOCK TABLE #{BUILDS_TABLE} IN SHARE UPDATE EXCLUSIVE MODE;
        LOCK TABLE ONLY #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE;
      SQL

      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{PARTITION_NAME}
          PARTITION OF #{TABLE_NAME}
          FOR VALUES IN (#{FIRST_PARTITION});
      SQL
    end
  end

  def down
    # no-op
    #
    # The migration should not remove the partition table since it might
    # have been created by 20230215074223_add_ci_runner_machine_builds_partitioned_table.rb.
    # In that case, the rollback would result in a different state.
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
