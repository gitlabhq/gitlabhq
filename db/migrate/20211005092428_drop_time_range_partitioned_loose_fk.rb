# frozen_string_literal: true

class DropTimeRangePartitionedLooseFk < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    # the table is not in use
    drop_table :loose_foreign_keys_deleted_records # rubocop: disable Migration/DropTable
  end

  def down
    constraint_name = check_constraint_name('loose_foreign_keys_deleted_records', 'deleted_table_name', 'max_length')
    execute(<<~SQL)
      CREATE TABLE loose_foreign_keys_deleted_records (
        created_at timestamp with time zone NOT NULL DEFAULT NOW(),
        deleted_table_name text NOT NULL,
        deleted_table_primary_key_value bigint NOT NULL,
        PRIMARY KEY (created_at, deleted_table_name, deleted_table_primary_key_value),
        CONSTRAINT #{constraint_name} CHECK ((char_length(deleted_table_name) <= 63))
      ) PARTITION BY RANGE (created_at);
    SQL

    min_date = Date.today - 1.month
    max_date = Date.today + 3.months
    create_daterange_partitions('loose_foreign_keys_deleted_records', 'created_at', min_date, max_date)
  end
end
