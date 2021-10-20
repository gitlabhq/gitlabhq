# frozen_string_literal: true

class AddRangePartitionedLooseFkTable < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  def up
    constraint_name = check_constraint_name('loose_foreign_keys_deleted_records', 'fully_qualified_table_name', 'max_length')
    execute(<<~SQL)
      CREATE TABLE loose_foreign_keys_deleted_records (
        id BIGSERIAL NOT NULL,
        partition bigint NOT NULL,
        primary_key_value bigint NOT NULL,
        status smallint NOT NULL DEFAULT 1,
        created_at timestamp with time zone NOT NULL DEFAULT NOW(),
        fully_qualified_table_name text NOT NULL,
        PRIMARY KEY (partition, id),
        CONSTRAINT #{constraint_name} CHECK ((char_length(fully_qualified_table_name) <= 150))
      ) PARTITION BY LIST (partition);

      CREATE TABLE gitlab_partitions_static.loose_foreign_keys_deleted_records_1
      PARTITION OF loose_foreign_keys_deleted_records
      FOR VALUES IN (1);
    SQL
  end

  def down
    drop_table :loose_foreign_keys_deleted_records
  end
end
