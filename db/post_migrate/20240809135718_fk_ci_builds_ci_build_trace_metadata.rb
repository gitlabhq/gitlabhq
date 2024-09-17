# frozen_string_literal: true

class FkCiBuildsCiBuildTraceMetadata < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '17.4'

  def up
    add_concurrent_partitioned_foreign_key(
      :p_ci_build_trace_metadata, :p_ci_builds,
      name: :fk_rails_aebc78111f_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_build_trace_metadata, :p_ci_builds,
        name: :fk_rails_aebc78111f_p, reverse_lock_order: true
    end
  end
end
