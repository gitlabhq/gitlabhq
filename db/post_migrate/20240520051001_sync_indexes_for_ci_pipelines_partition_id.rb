# frozen_string_literal: true

class SyncIndexesForCiPipelinesPartitionId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  TABLE = :ci_pipelines
  INDEXES = [
    {
      name: :index_ci_pipelines_on_id_and_partition_id,
      columns: [:id, :partition_id],
      options: { unique: true }
    },
    {
      name: :index_ci_pipelines_on_project_id_and_iid_and_partition_id,
      columns: [:project_id, :iid, :partition_id],
      options: { unique: true, where: 'iid IS NOT NULL' }
    }
  ]

  def up
    INDEXES.each do |definition|
      name, columns, options = definition.values_at(:name, :columns, :options)
      add_concurrent_index(TABLE, columns, name: name, **options)
    end
  end

  def down
    INDEXES.each do |definition|
      remove_concurrent_index_by_name(TABLE, definition[:name])
    end
  end
end
