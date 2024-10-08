# frozen_string_literal: true

class CreatePartitionsForPCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    return if already_partitioned?

    execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_build_trace_metadata_100"
        PARTITION OF "p_ci_build_trace_metadata" FOR VALUES IN (100);

      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_build_trace_metadata_101"
        PARTITION OF "p_ci_build_trace_metadata" FOR VALUES IN (101);

      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_build_trace_metadata_102"
        PARTITION OF "p_ci_build_trace_metadata" FOR VALUES IN (102);
    SQL
  end

  def down; end

  private

  def already_partitioned?
    ::Gitlab::Database::PostgresPartition
      .for_parent_table(:p_ci_build_trace_metadata)
      .partition_exists?(:ci_build_trace_metadata)
  end
end
