# frozen_string_literal: true

class AddFkIndexToCiJobVariablesOnPartitionIdAndJobId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_job_variables_on_partition_id_job_id
  TABLE_NAME = :ci_job_variables
  COLUMNS = [:partition_id, :job_id]

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
