# frozen_string_literal: true

class RemoveIndexFromCiRunnerMachinesOnIpAddress < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '19.1'

  INDEX_NAME = :index_ci_runner_machines_on_ip_address

  # These are the auto-generated hash names created by add_concurrent_partitioned_index,
  # later renamed to human-readable names by migration 20250821174558.
  PARTITION_INDEX_RENAMES = {
    index_d2746151f0: :index_instance_type_ci_runner_machines_on_ip_address,
    index_ee7c87e634: :index_group_type_ci_runner_machines_on_ip_address,
    index_053d12f7ee: :index_project_type_ci_runner_machines_on_ip_address
  }.freeze

  def up
    remove_concurrent_partitioned_index_by_name :ci_runner_machines, INDEX_NAME
  end

  def down
    add_concurrent_partitioned_index :ci_runner_machines, :ip_address, name: INDEX_NAME

    schema = connection.current_schema
    rename_sql = PARTITION_INDEX_RENAMES.map do |from, to|
      "ALTER INDEX IF EXISTS #{connection.quote_table_name("#{schema}.#{from}")} " \
        "RENAME TO #{connection.quote_column_name(to)}"
    end.join('; ')

    with_lock_retries do
      execute rename_sql
    end
  end
end
