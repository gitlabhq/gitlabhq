# frozen_string_literal: true

class AddTmpIndexToCiSourcesPipelinesOnPartitionId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :tmp_index_ci_sources_pipelines_on_partition_id_and_id
  SOURCE_INDEX_NAME = :tmp_index_ci_sources_pipelines_on_source_partition_id_and_id
  TABLE_NAME = :ci_sources_pipelines

  def up
    return unless Gitlab.com?

    add_concurrent_index TABLE_NAME,
      [:partition_id, :id],
      name: INDEX_NAME, where: 'partition_id = 101'

    add_concurrent_index TABLE_NAME,
      [:source_partition_id, :id],
      name: SOURCE_INDEX_NAME,
      where: 'source_partition_id = 101'
  end

  def down
    return unless Gitlab.com?

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
    remove_concurrent_index_by_name TABLE_NAME, SOURCE_INDEX_NAME
  end
end
