# frozen_string_literal: true

class PrepareCiBuildsPrimaryKeyForPartitioning < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!

  TABLE_NAME = :ci_builds
  PRIMARY_KEY = :ci_builds_pkey
  NEW_INDEX_NAME = :index_ci_builds_on_id_partition_id_unique
  OLD_INDEX_NAME = :index_ci_builds_on_id_unique

  def up
    swap_primary_key(TABLE_NAME, PRIMARY_KEY, NEW_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, :id, unique: true, name: OLD_INDEX_NAME)
    add_concurrent_index(TABLE_NAME, [:id, :partition_id], unique: true, name: NEW_INDEX_NAME)

    unswap_primary_key(TABLE_NAME, PRIMARY_KEY, OLD_INDEX_NAME)

    recreate_partitioned_foreign_keys
  end

  private

  def recreate_partitioned_foreign_keys
    add_partitioned_fk(:ci_job_variables, :fk_rails_fbf3b34792_p, column: :job_id)
    add_partitioned_fk(:ci_job_artifacts, :fk_rails_c5137cb2c1_p, column: :job_id)
    add_partitioned_fk(:ci_running_builds, :fk_rails_da45cfa165_p)
    add_partitioned_fk(:ci_build_pending_states, :fk_861cd17da3_p)
    add_partitioned_fk(:ci_build_trace_chunks, :fk_89e29fa5ee_p)
    add_partitioned_fk(:ci_unit_test_failures, :fk_9e0fc58930_p)
    add_partitioned_fk(:ci_build_trace_metadata, :fk_rails_aebc78111f_p)
    add_partitioned_fk(:ci_pending_builds, :fk_rails_725a2644a3_p)
    add_partitioned_fk(:ci_builds_runner_session, :fk_rails_70707857d3_p)
    add_partitioned_fk(:ci_build_needs, :fk_rails_3cf221d4ed_p)
    add_partitioned_fk(:ci_build_report_results, :fk_rails_16cb1ff064_p)
    add_partitioned_fk(:ci_resources, :fk_e169a8e3d5_p, delete: :nullify)
    add_partitioned_fk(:ci_sources_pipelines, :fk_be5624bf37_p, columns: %i[source_partition_id source_job_id])

    add_routing_table_fk(:p_ci_builds_metadata, :fk_e20479742e_p)
    add_routing_table_fk(:p_ci_runner_machine_builds, :fk_bb490f12fe_p)
  end

  def add_partitioned_fk(source_table, name, column: :build_id, columns: nil, delete: :cascade)
    add_concurrent_foreign_key(source_table, :ci_builds,
      column: columns || [:partition_id, column],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: delete,
      name: name)
  end

  def add_routing_table_fk(source_table, name)
    add_concurrent_partitioned_foreign_key(source_table, :ci_builds,
      column: [:partition_id, :build_id],
      target_column: [:partition_id, :id],
      reverse_lock_order: true,
      on_update: :cascade,
      on_delete: :cascade,
      name: name)
  end
end
