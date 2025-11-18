# frozen_string_literal: true

class RemoveOrganizationIdFromUniqueIndexesOnCiRunnerMachines < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :ci_runner_machines
  INDEX_NAME = :idx_ci_runner_machines_on_runner_id_type_system_xid_org_id

  def up
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  def down
    # no-op, as the original 20251103123729_add_organization_id_to_unique_indexes_on_ci_runner_machines.rb migration
    # as no-oped
  end
end
