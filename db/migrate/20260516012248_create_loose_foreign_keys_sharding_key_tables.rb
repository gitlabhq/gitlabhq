# frozen_string_literal: true

class CreateLooseForeignKeysShardingKeyTables < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '19.1'

  disable_ddl_transaction!

  SHARDING_TABLES = {
    loose_foreign_keys_organization_deleted_records: [
      :organization_id,
      :index_lfk_organization_deleted_records_partitioned_query
    ],
    loose_foreign_keys_namespace_deleted_records: [
      :namespace_id,
      :index_lfk_namespace_deleted_records_partitioned_query
    ],
    loose_foreign_keys_project_deleted_records: [
      :project_id,
      :index_lfk_project_deleted_records_partitioned_query
    ],
    loose_foreign_keys_user_deleted_records: [
      :user_id,
      :index_lfk_user_deleted_records_partitioned_query
    ]
  }.freeze

  TABLE_CONFIG = {
    primary_key: [:partition, :id],
    options: 'PARTITION BY LIST (partition)',
    if_not_exists: true
  }

  def up
    SHARDING_TABLES.each do |table_name, options|
      sharding_key, partition_query_index_name = options

      create_table table_name, **TABLE_CONFIG do |t|
        t.uuid :id, null: false, default: -> { 'gen_random_uuid_v7()' }
        t.bigint :partition, null: false, default: 1
        t.bigint :primary_key_value, null: false
        t.bigint sharding_key, null: false
        t.datetime_with_timezone :consume_after, default: -> { 'NOW()' }
        t.datetime_with_timezone :created_at, null: false, default: -> { 'NOW()' }
        t.integer :status, null: false, default: 1, limit: 2
        t.integer :cleanup_attempts, limit: 2, default: 0
        t.text :fully_qualified_table_name, null: false

        t.index(
          [:partition, :fully_qualified_table_name, :consume_after, :id],
          name: partition_query_index_name,
          where: 'status = 1'
        )
      end

      add_text_limit(table_name, :fully_qualified_table_name, 150)

      # Initialize partitions
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.#{table_name}_1
        PARTITION OF #{table_name}
        FOR VALUES IN (1);
      SQL
    end
  end

  def down
    SHARDING_TABLES.each_key { |table_name| drop_table table_name }
  end
end
