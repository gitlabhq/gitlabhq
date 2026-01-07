# frozen_string_literal: true

class ReplaceUniqueIndexOnBackgroundOperationWorkers < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.8'

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_background_operation_workers_on_unique_configuration'
  NEW_INDEX_NAME = 'index_bow_on_unique_undone'

  def up
    remove_concurrent_partitioned_index_by_name :background_operation_workers, OLD_INDEX_NAME

    add_concurrent_partitioned_index(
      :background_operation_workers,
      [:partition, :organization_id, :job_class_name, :table_name, :column_name, :job_arguments],
      unique: true,
      name: NEW_INDEX_NAME,
      where: 'status IN (0, 1, 2)'
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name :background_operation_workers, NEW_INDEX_NAME

    add_concurrent_partitioned_index(
      :background_operation_workers,
      [:partition, :organization_id, :job_class_name, :table_name, :column_name, :job_arguments],
      unique: true,
      name: OLD_INDEX_NAME
    )
  end
end
