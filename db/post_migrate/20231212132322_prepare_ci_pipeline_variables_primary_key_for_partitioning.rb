# frozen_string_literal: true

class PrepareCiPipelineVariablesPrimaryKeyForPartitioning < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_variables
  PRIMARY_KEY = :ci_pipeline_variables_pkey
  NEW_INDEX = :index_ci_pipeline_variables_on_id_partition_id_unique
  OLD_INDEX = :index_ci_pipeline_variables_on_id_unique

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX)
  end
end
