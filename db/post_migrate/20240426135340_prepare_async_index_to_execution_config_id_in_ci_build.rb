# frozen_string_literal: true

class PrepareAsyncIndexToExecutionConfigIdInCiBuild < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.0'

  INDEX_NAME = 'index_p_ci_builds_on_execution_config_id'
  COLUMNS = [:execution_config_id]

  def up
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      index_name = generated_index_name(partition.identifier, INDEX_NAME)
      prepare_async_index(partition.identifier, COLUMNS, name: index_name, where: "execution_config_id IS NOT NULL")
    end
  end

  def down
    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds) do |partition|
      index_name = generated_index_name(partition.identifier, INDEX_NAME)
      unprepare_async_index(partition.identifier, index_name)
    end
  end
end
