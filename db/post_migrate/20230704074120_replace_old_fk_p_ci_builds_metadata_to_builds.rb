# frozen_string_literal: true

class ReplaceOldFkPCiBuildsMetadataToBuilds < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  disable_ddl_transaction!

  def up
    return unless should_run?
    return if new_foreign_key_exists?

    with_lock_retries do
      remove_foreign_key_if_exists :p_ci_builds_metadata, :ci_builds,
        name: :fk_e20479742e_p, reverse_lock_order: true

      rename_constraint :p_ci_builds_metadata, :temp_fk_e20479742e_p, :fk_e20479742e_p

      Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds_metadata) do |partition|
        rename_constraint partition.identifier, :temp_fk_e20479742e_p, :fk_e20479742e_p
      end
    end
  end

  def down
    return unless should_run?
    return unless new_foreign_key_exists?

    add_concurrent_partitioned_foreign_key :p_ci_builds_metadata, :ci_builds,
      name: :temp_fk_e20479742e_p,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      on_update: :cascade,
      on_delete: :cascade,
      validate: true,
      reverse_lock_order: true

    switch_constraint_names :p_ci_builds_metadata, :fk_e20479742e_p, :temp_fk_e20479742e_p

    Gitlab::Database::PostgresPartitionedTable.each_partition(:p_ci_builds_metadata) do |partition|
      switch_constraint_names partition.identifier, :fk_e20479742e_p, :temp_fk_e20479742e_p
    end
  end

  private

  def should_run?
    can_execute_on?(:ci_builds_metadata, :ci_builds)
  end

  def new_foreign_key_exists?
    foreign_key_exists?(:p_ci_builds_metadata, :p_ci_builds, name: :fk_e20479742e_p)
  end
end
