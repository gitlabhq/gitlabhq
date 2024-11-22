# frozen_string_literal: true

class CreatePartitionedCiRunners < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = 'ci_runners'
  PARTITIONED_TABLE_PK = %w[id runner_type]
  CONSTRAINT_NAME = 'check_sharding_key_id_nullness'

  def up
    partition_table_by_list(
      TABLE_NAME, 'runner_type', primary_key: PARTITIONED_TABLE_PK,
      partition_mappings: { instance_type: 1, group_type: 2, project_type: 3 },
      partition_name_format: '%{partition_name}_%{table_name}',
      create_partitioned_table_fn: ->(name) { create_partitioned_table(name) }
    )

    Gitlab::Database::PostgresPartitionedTable.each_partition(:ci_runners_e59bb2812d) do |partition|
      source = partition.to_s

      add_check_constraint(source,
        source.start_with?('instance_type') ? 'sharding_key_id IS NULL' : 'sharding_key_id IS NOT NULL',
        CONSTRAINT_NAME)
    end
  end

  def down
    drop_partitioned_table_for(TABLE_NAME)
  end

  private

  def create_partitioned_table(name)
    options = 'PARTITION BY LIST (runner_type)'
    create_table name, primary_key: PARTITIONED_TABLE_PK, options: options do |t|
      t.bigint :id, null: false
      t.bigint :creator_id
      t.bigint :sharding_key_id, null: true
      t.timestamps_with_timezone null: true
      t.datetime_with_timezone :contacted_at
      t.datetime_with_timezone :token_expires_at
      t.float :public_projects_minutes_cost_factor, null: false, default: 1.0
      t.float :private_projects_minutes_cost_factor, null: false, default: 1.0
      t.integer :access_level, null: false, default: 0
      t.integer :maximum_timeout
      t.integer :runner_type, null: false, limit: 2
      t.integer :registration_type, null: false, limit: 2, default: 0
      t.integer :creation_state, null: false, limit: 2, default: 0
      t.boolean :active, null: false, default: true
      t.boolean :run_untagged, null: false, default: true
      t.boolean :locked, null: false, default: false
      t.text :name, limit: 256
      t.text :token_encrypted, limit: 128
      t.text :token, limit: 128
      t.text :description, limit: 1024
      t.text :maintainer_note, limit: 1024
      t.text :allowed_plans, array: true, null: false, default: []
      t.bigint :allowed_plan_ids, array: true, null: false, default: []

      t.index [:token_encrypted, :runner_type], name: "index_uniq_#{name}_on_token_encrypted_and_type", unique: true
      t.index [:token, :runner_type], name: "idx_uniq_#{name}_on_token_and_type_where_not_null", unique: true,
        where: "token IS NOT NULL"
      t.index :creator_id, name: "index_#{name}_on_creator_id_where_not_null",
        where: 'creator_id IS NOT NULL'
      t.index :sharding_key_id, name: "index_#{name}_on_sharding_key_id_where_not_null",
        where: 'sharding_key_id IS NOT NULL'
      t.index %i[active id], name: "index_#{name}_on_active_and_id"
      t.index %i[contacted_at id], name: "index_#{name}_on_contacted_at_and_id_desc",
        order: { contacted_at: :asc, id: :desc }
      t.index %i[contacted_at id], name: "idx_#{name}_on_contacted_at_and_id_where_inactive",
        order: { contacted_at: :desc, runner_type: :asc, id: :desc }, where: 'active = false'
      t.index %i[contacted_at id], name: "index_#{name}_on_contacted_at_desc_and_id_desc",
        order: { contacted_at: :desc, runner_type: :asc, id: :desc }
      t.index %i[created_at id], name: "index_#{name}_on_created_at_and_id_desc",
        order: { runner_type: :asc, id: :desc }
      t.index %i[created_at id], name: "index_#{name}_on_created_at_and_id_where_inactive",
        order: { created_at: :desc, runner_type: :asc, id: :desc }, where: 'active = false'
      t.index %i[created_at id], name: "index_#{name}_on_created_at_desc_and_id_desc",
        order: { created_at: :desc, runner_type: :asc, id: :desc }
      t.index :description, name: "index_#{name}_on_description_trigram", using: :gin, opclass: :gin_trgm_ops
      t.index :locked, name: "index_#{name}_on_locked"
      t.index %i[token_expires_at id], name: "index_#{name}_on_token_expires_at_and_id_desc",
        order: { runner_type: :asc, id: :desc }
      t.index %i[token_expires_at id], name: "idx_#{name}_on_token_expires_at_desc_and_id_desc",
        order: { token_expires_at: :desc, runner_type: :asc, id: :desc }
    end
  end
end
