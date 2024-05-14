# frozen_string_literal: true

class CreatePartitionsForPCiBuildsExecutionConfigs < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def up
    with_lock_retries do
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_100
          PARTITION OF p_ci_builds_execution_configs
          FOR VALUES IN (100);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_101
          PARTITION OF p_ci_builds_execution_configs
          FOR VALUES IN (101);

        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_102
          PARTITION OF p_ci_builds_execution_configs
          FOR VALUES IN (102);
      SQL
    end
  end

  def down
    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_100;
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_101;
      DROP TABLE IF EXISTS gitlab_partitions_dynamic.ci_builds_execution_configs_102;
    SQL
  end
end
