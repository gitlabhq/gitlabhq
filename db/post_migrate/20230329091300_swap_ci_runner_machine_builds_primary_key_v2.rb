# frozen_string_literal: true

class SwapCiRunnerMachineBuildsPrimaryKeyV2 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :p_ci_runner_machine_builds
  BUILDS_TABLE = :ci_builds

  def up
    reorder_primary_key_columns([:build_id, :partition_id])
  end

  def down
    reorder_primary_key_columns([:partition_id, :build_id])
  end

  private

  def reorder_primary_key_columns(columns)
    with_lock_retries(raise_on_exhaustion: true) do
      connection.execute(<<~SQL)
        LOCK TABLE #{BUILDS_TABLE}, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE;
      SQL

      partitions = Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME).to_a
      partitions.each { |partition| drop_table partition.identifier }

      execute <<~SQL
        ALTER TABLE #{TABLE_NAME}
          DROP CONSTRAINT p_ci_runner_machine_builds_pkey CASCADE;

        ALTER TABLE #{TABLE_NAME}
          ADD PRIMARY KEY (#{columns.join(', ')});
      SQL

      partitions.each do |partition|
        connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{partition.identifier}
            PARTITION OF #{partition.parent_identifier} #{partition.condition};
        SQL
      end
    end
  end
end
