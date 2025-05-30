# frozen_string_literal: true

class RemoveRedundantCiPartitionIdIndexes < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  COLUMNS = [:partition_id, :build_id]

  TABLE_NAME_1 = :ci_build_trace_chunks
  INDEX_NAME_1 = :index_ci_build_trace_chunks_on_partition_id_build_id

  TABLE_NAME_2 = :ci_resources
  INDEX_NAME_2 = :index_ci_resources_on_partition_id_build_id

  TABLE_NAME_3 = :ci_unit_test_failures
  INDEX_NAME_3 = :index_ci_unit_test_failures_on_partition_id_build_id

  def up
    remove_concurrent_index_by_name TABLE_NAME_1, name: INDEX_NAME_1
    remove_concurrent_index_by_name TABLE_NAME_2, name: INDEX_NAME_2
    remove_concurrent_index_by_name TABLE_NAME_3, name: INDEX_NAME_3
  end

  def down
    add_concurrent_index TABLE_NAME_1, COLUMNS, name: INDEX_NAME_1
    add_concurrent_index TABLE_NAME_2, COLUMNS, name: INDEX_NAME_2
    add_concurrent_index TABLE_NAME_3, COLUMNS, name: INDEX_NAME_3
  end
end
