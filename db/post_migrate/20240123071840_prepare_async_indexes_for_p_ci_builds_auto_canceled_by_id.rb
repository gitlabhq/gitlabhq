# frozen_string_literal: true

class PrepareAsyncIndexesForPCiBuildsAutoCanceledById < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '16.9'
  disable_ddl_transaction!

  INDEX_NAME = "p_ci_builds_auto_canceled_by_id_bigint_idx"
  TABLE_NAME = :p_ci_builds
  COLUMN_NAME = :auto_canceled_by_id_convert_to_bigint
  WHERE_CLAUSE = "auto_canceled_by_id_convert_to_bigint IS NOT NULL"

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      index_name = generated_index_name(partition.identifier, INDEX_NAME)
      prepare_async_index partition.identifier, COLUMN_NAME, name: index_name, where: WHERE_CLAUSE
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      index_name = generated_index_name(partition.identifier, INDEX_NAME)
      unprepare_async_index partition.identifier, COLUMN_NAME, name: index_name, where: WHERE_CLAUSE
    end
  end
end
