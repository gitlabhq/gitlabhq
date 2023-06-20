# frozen_string_literal: true

class AddIndexOnCiJobAnnotations < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_p_ci_job_annotations_on_partition_id_job_id_name'

  def up
    add_concurrent_partitioned_index(
      :p_ci_job_annotations,
      [:partition_id, :job_id, :name],
      name: INDEX_NAME,
      unique: true
    )
  end

  def down
    remove_concurrent_partitioned_index_by_name :p_ci_job_annotations, INDEX_NAME
  end
end
