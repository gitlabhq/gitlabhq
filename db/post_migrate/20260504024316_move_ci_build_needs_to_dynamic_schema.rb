# frozen_string_literal: true

class MoveCiBuildNeedsToDynamicSchema < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '19.0'
  skip_require_disable_ddl_transactions!

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_NAME = :ci_build_needs

  def up
    return unless can_execute_on?(TABLE_NAME)

    connection.execute(<<~SQL)
      ALTER TABLE IF EXISTS #{TABLE_NAME} SET SCHEMA #{DYNAMIC_SCHEMA};
    SQL
  end

  def down
    return unless can_execute_on?(TABLE_NAME)

    table_identifier = "#{DYNAMIC_SCHEMA}.#{TABLE_NAME}"

    if table_exists?(table_identifier)
      connection.execute(<<~SQL)
        ALTER TABLE IF EXISTS #{table_identifier} SET SCHEMA #{connection.current_schema};
      SQL
    else # In tests we set the database from structure.sql, so the table doesn't exist
      remove_dynamic_partitions
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS #{TABLE_NAME} PARTITION OF p_#{TABLE_NAME}
          FOR VALUES IN (100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111);
      SQL
    end
  end

  private

  def remove_dynamic_partitions
    (100..111).each { |n| drop_partition(n) }
  end

  def drop_partition(number)
    identifier = "#{DYNAMIC_SCHEMA}.#{TABLE_NAME}_#{number}"
    return unless table_exists?(identifier)

    connection.execute(<<~SQL)
      ALTER TABLE p_#{TABLE_NAME} DETACH PARTITION #{identifier};

      DROP TABLE IF EXISTS #{identifier};
    SQL
  end
end
