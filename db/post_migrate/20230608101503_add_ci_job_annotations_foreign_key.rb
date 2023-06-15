# frozen_string_literal: true

class AddCiJobAnnotationsForeignKey < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key(
      :p_ci_job_annotations, :p_ci_builds,
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    remove_foreign_key_if_exists :p_ci_job_annotations, :p_ci_builds
  end
end
