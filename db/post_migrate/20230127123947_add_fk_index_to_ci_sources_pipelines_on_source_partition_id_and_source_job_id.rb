# frozen_string_literal: true

class AddFkIndexToCiSourcesPipelinesOnSourcePartitionIdAndSourceJobId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :index_ci_sources_pipelines_on_source_partition_id_source_job_id
  TABLE_NAME = :ci_sources_pipelines
  COLUMNS = [:source_partition_id, :source_job_id]

  def up
    add_concurrent_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
