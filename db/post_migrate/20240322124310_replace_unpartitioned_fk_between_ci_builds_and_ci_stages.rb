# frozen_string_literal: true

class ReplaceUnpartitionedFkBetweenCiBuildsAndCiStages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  milestone '16.11'
  disable_ddl_transaction!

  TABLE_NAME = :p_ci_builds
  REFERENCED_TABLE_NAME = :ci_stages
  PARTITIONED_REFERENCED_TABLE_NAME = :p_ci_stages
  FK_NAME = :fk_3a9eaa254d_p
  TMP_FK_NAME = :tmp_fk_3a9eaa254d_p

  def up
    if foreign_key_exists?(TABLE_NAME, PARTITIONED_REFERENCED_TABLE_NAME, name: FK_NAME)
      with_lock_retries do
        remove_foreign_key_if_exists(
          TABLE_NAME,
          PARTITIONED_REFERENCED_TABLE_NAME,
          name: TMP_FK_NAME,
          reverse_lock_order: true)
      end

      return
    end

    with_lock_retries do
      execute("LOCK TABLE #{PARTITIONED_REFERENCED_TABLE_NAME}, #{TABLE_NAME} IN ACCESS EXCLUSIVE MODE")

      remove_foreign_key_if_exists(TABLE_NAME, REFERENCED_TABLE_NAME, name: FK_NAME, reverse_lock_order: true)
      rename_constraint(TABLE_NAME, TMP_FK_NAME, FK_NAME)

      Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
        rename_constraint(partition.identifier, TMP_FK_NAME, FK_NAME)
      end
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(
      TABLE_NAME,
      REFERENCED_TABLE_NAME,
      name: TMP_FK_NAME,
      column: [:partition_id, :stage_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true
    )

    switch_constraint_names(TABLE_NAME, FK_NAME, TMP_FK_NAME)

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      switch_constraint_names(partition.identifier, FK_NAME, TMP_FK_NAME)
    end
  end
end
