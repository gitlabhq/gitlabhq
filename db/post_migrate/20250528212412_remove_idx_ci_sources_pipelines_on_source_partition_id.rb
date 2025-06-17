# frozen_string_literal: true

class RemoveIdxCiSourcesPipelinesOnSourcePartitionId < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  disable_ddl_transaction!

  TABLE_NAME = :ci_sources_pipelines
  INDEX_NAME = :index_ci_sources_pipelines_on_source_partition_id_source_job_id
  COLUMNS = [:source_partition_id, :source_job_id]

  def up
    remove_concurrent_index_by_name TABLE_NAME, name: INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, COLUMNS, name: INDEX_NAME
  end
end
