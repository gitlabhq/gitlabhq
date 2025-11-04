# frozen_string_literal: true

class AddOrganizationIdToUniqueIndexesOnCiRunnerMachines < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.6'

  TABLE_NAME = :ci_runner_machines
  INDEX_NAME = :idx_ci_runner_machines_on_runner_id_type_system_xid_org_id
  COLUMN_NAMES = %i[runner_id runner_type system_xid organization_id].freeze
  PARTITION_INDEX_NAMES = {
    index_97ff649ee0: :idx_inst_ci_runner_machines_on_runner_id_type_system_xid_org_id,
    index_a722fa908d: :idx_grp_ci_runner_machines_on_runner_id_type_system_xid_org_id,
    index_ad8066c195: :idx_proj_ci_runner_machines_on_runner_id_type_system_xid_org_id
  }.freeze

  def up
    add_concurrent_partitioned_index(TABLE_NAME, COLUMN_NAMES, unique: true, name: INDEX_NAME)

    with_lock_retries do
      schema_name = connection.current_schema
      statements = PARTITION_INDEX_NAMES.map do |old_name, new_name|
        <<~SQL
          ALTER INDEX IF EXISTS #{connection.quote_table_name("#{schema_name}.#{connection.quote_column_name(old_name)}")}
                      RENAME TO #{connection.quote_column_name(new_name)}
        SQL
      end

      connection.execute(statements.join(';'))
    end
  end

  def down
    remove_concurrent_partitioned_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
