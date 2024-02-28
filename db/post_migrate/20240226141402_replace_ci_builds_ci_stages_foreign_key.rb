# frozen_string_literal: true

class ReplaceCiBuildsCiStagesForeignKey < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '16.10'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds
  FK_NAME = :tmp_fk_3a9eaa254d_p

  def up
    add_concurrent_partitioned_foreign_key(
      TABLE_NAME,
      :p_ci_stages,
      name: FK_NAME,
      column: [:partition_id, :stage_id],
      target_column: [:partition_id, :id],
      on_delete: :cascade,
      on_update: :cascade,
      validate: false,
      reverse_lock_order: true
    )

    prepare_partitioned_async_foreign_key_validation(TABLE_NAME, name: FK_NAME)
  end

  def down
    unprepare_partitioned_async_foreign_key_validation(TABLE_NAME, name: FK_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      remove_foreign_key_if_exists(partition.identifier, name: FK_NAME)
    end
  end
end
