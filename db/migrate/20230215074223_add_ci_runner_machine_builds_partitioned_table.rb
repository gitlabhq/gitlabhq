# frozen_string_literal: true

class AddCiRunnerMachineBuildsPartitionedTable < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  enable_lock_retries!

  TABLE_NAME = :ci_runner_machine_builds
  PARENT_TABLE_NAME = :p_ci_runner_machine_builds
  FIRST_PARTITION = 100

  def up
    execute(<<~SQL)
      CREATE TABLE #{PARENT_TABLE_NAME} (
        partition_id bigint NOT NULL,
        build_id bigint NOT NULL,
        runner_machine_id bigint NOT NULL,
        PRIMARY KEY (partition_id, build_id),
        CONSTRAINT fk_bb490f12fe_p FOREIGN KEY (partition_id, build_id) REFERENCES ci_builds(partition_id, id) ON UPDATE CASCADE ON DELETE CASCADE
      )
      PARTITION BY LIST (partition_id);

      CREATE INDEX index_ci_runner_machine_builds_on_runner_machine_id ON #{PARENT_TABLE_NAME} USING btree (runner_machine_id);
    SQL
  end

  def down
    drop_table PARENT_TABLE_NAME
  end
end
