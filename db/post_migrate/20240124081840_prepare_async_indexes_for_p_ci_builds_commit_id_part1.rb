# frozen_string_literal: true

class PrepareAsyncIndexesForPCiBuildsCommitIdPart1 < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  INDEXES = [
    [[:commit_id_convert_to_bigint, :status, :type], "p_ci_builds_commit_id_bigint_status_type_idx"],
    [[:commit_id_convert_to_bigint, :type, :name, :ref], "p_ci_builds_commit_id_bigint_type_name_ref_idx"]
  ]
  TABLE_NAME = :p_ci_builds

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |columns, routing_table_index_name|
        index_name = generated_index_name(partition.identifier, routing_table_index_name)
        prepare_async_index partition.identifier, columns, name: index_name
      end
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      INDEXES.each do |columns, routing_table_index_name|
        index_name = generated_index_name(partition.identifier, routing_table_index_name)
        unprepare_async_index partition.identifier, columns, name: index_name
      end
    end
  end
end
