# frozen_string_literal: true

class CreatePartitionedCiRunnerManagers < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = 'ci_runner_machines'
  PARTITIONED_TABLE_NAME = :ci_runner_machines_687967fa8a
  PARTITIONED_TABLE_PK = %w[id runner_type]

  def up
    partition_table_by_list(
      TABLE_NAME, 'runner_type', primary_key: PARTITIONED_TABLE_PK,
      partition_mappings: { instance_type: 1, group_type: 2, project_type: 3 },
      partition_name_format: '%{partition_name}_%{table_name}',
      create_partitioned_table_fn: ->(name) { create_partitioned_table(name) }
    )
  end

  def down
    drop_partitioned_table_for(TABLE_NAME)
  end

  private

  def create_partitioned_table(name)
    options = 'PARTITION BY LIST (runner_type)'
    create_table name, primary_key: PARTITIONED_TABLE_PK, options: options do |t|
      t.bigint :id, null: false
      t.bigint :runner_id, null: false
      t.bigint :sharding_key_id, null: true
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :contacted_at
      t.integer :creation_state, null: false, limit: 2, default: 0
      t.integer :executor_type, null: true, limit: 2
      t.integer :runner_type, null: false, limit: 2
      t.jsonb :config, null: false, default: {}
      t.text :system_xid, null: false, limit: 64
      t.text :platform, limit: 255
      t.text :architecture, limit: 255
      t.text :revision, limit: 255
      t.text :ip_address, limit: 1024
      t.text :version, limit: 2048

      t.index [:runner_id, :runner_type, :system_xid], name: "idx_uniq_#{name}_on_runner_id_system_xid", unique: true
      t.index :sharding_key_id, name: "idx_#{name}_on_sharding_key_where_notnull",
        where: 'sharding_key_id IS NOT NULL'
      t.index %i[contacted_at id], name: "idx_#{name}_on_contacted_at_desc_id_desc",
        order: { contacted_at: :desc, id: :desc }
      t.index %i[created_at id], name: "index_#{name}_on_created_at_and_id_desc",
        order: { runner_type: :asc, id: :desc }
      t.index %q[((substring(version from '^\d+\.'))), version, runner_id], name: "index_#{name}_on_major_version"
      t.index %q[((substring(version from '^\d+\.\d+\.'))), version, runner_id], name: "index_#{name}_on_minor_version"
      t.index %q[((substring(version from '^\d+\.\d+\.\d+'))), version, runner_id],
        name: "index_#{name}_on_patch_version"
      t.index :version, name: "index_#{name}_on_version"
    end
  end
end
