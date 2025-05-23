# frozen_string_literal: true

class AddIndexToCiRunnerMachinesOnIpAddress < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.1'

  INDEX_NAME = :index_ci_runner_machines_on_ip_address

  def up
    add_concurrent_partitioned_index :ci_runner_machines, :ip_address, name: INDEX_NAME
  end

  def down
    remove_concurrent_partitioned_index_by_name :ci_runner_machines, INDEX_NAME
  end
end
