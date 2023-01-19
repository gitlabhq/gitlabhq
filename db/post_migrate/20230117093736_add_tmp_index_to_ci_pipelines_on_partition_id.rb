# frozen_string_literal: true

class AddTmpIndexToCiPipelinesOnPartitionId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = :tmp_index_ci_pipelines_on_partition_id_and_id

  def up
    return unless Gitlab.com?

    prepare_async_index :ci_pipelines, [:partition_id, :id], name: INDEX_NAME, where: 'partition_id = 101'
  end

  def down
    return unless Gitlab.com?

    unprepare_async_index :ci_pipelines, [:partition_id, :id], name: INDEX_NAME, where: 'partition_id = 101'
  end
end
