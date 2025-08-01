# frozen_string_literal: true

class AddFkToCiBuildsFromDefinitionInstances < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.3'
  disable_ddl_transaction!

  SOURCE_TABLE_NAME = :p_ci_job_definition_instances
  TARGET_TABLE_NAME = :p_ci_builds
  FK_NAME = :fk_rails_6af6965da7_p

  def up
    add_concurrent_partitioned_foreign_key(
      SOURCE_TABLE_NAME, TARGET_TABLE_NAME,
      column: [:partition_id, :job_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      reverse_lock_order: true,
      name: FK_NAME
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists(
        SOURCE_TABLE_NAME,
        TARGET_TABLE_NAME,
        reverse_lock_order: true,
        name: FK_NAME
      )
    end
  end
end
