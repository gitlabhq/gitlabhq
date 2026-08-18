# frozen_string_literal: true

class RemovePCiBuildsMetadataForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.3'

  SOURCE_TABLE = :p_ci_builds_metadata
  TARGET_TABLE = :p_ci_builds
  FOREIGN_KEY_NAME = :fk_e20479742e_p

  def up
    remove_partitioned_foreign_key SOURCE_TABLE, TARGET_TABLE,
      name: FOREIGN_KEY_NAME, reverse_lock_order: true
  end

  def down
    add_concurrent_partitioned_foreign_key SOURCE_TABLE, TARGET_TABLE,
      column: %i[partition_id build_id],
      target_column: %i[partition_id id],
      name: FOREIGN_KEY_NAME,
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true
  end
end
