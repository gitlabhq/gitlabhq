# frozen_string_literal: true

class ReplacePCiBuildsMetadataForeignKeyV5 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key :p_ci_builds_metadata, :p_ci_builds,
      name: :temp_fk_e20479742e_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_builds_metadata, :p_ci_builds,
        name: :temp_fk_e20479742e_p,
        reverse_lock_order: true
    end
  end
end
