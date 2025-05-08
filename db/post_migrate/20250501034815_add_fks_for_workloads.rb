# frozen_string_literal: true

class AddFksForWorkloads < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '18.0'
  disable_ddl_transaction!

  FK_NAME = :fk_rails_74f339da60

  def up
    return unless can_execute_on?(:ci_pipelines)

    add_concurrent_partitioned_foreign_key(
      :p_ci_workloads, :p_ci_pipelines,
      name: FK_NAME,
      column: [:partition_id, :pipeline_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_workloads, :p_ci_pipelines, name: FK_NAME, reverse_lock_order: true
    end
  end
end
