# frozen_string_literal: true

class RemoveFkToCiBuildsPCiBuildsMetadataOnBuildId < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_builds_metadata
  TARGET_TABLE_NAME = :ci_builds
  FK_NAME = :fk_e20479742e

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        name: FK_NAME,
        reverse_lock_order: true
      )
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME,
      TARGET_TABLE_NAME,
      column: :build_id,
      on_delete: :cascade,
      name: FK_NAME
    )
  end
end
