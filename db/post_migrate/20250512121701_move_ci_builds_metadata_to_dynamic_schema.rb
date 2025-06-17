# frozen_string_literal: true

class MoveCiBuildsMetadataToDynamicSchema < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::WraparoundAutovacuum

  milestone '18.1'

  DYNAMIC_SCHEMA = Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
  TABLE_NAME = :ci_builds_metadata

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
      connection.execute(<<~SQL)
        DROP TABLE IF EXISTS #{DYNAMIC_SCHEMA}.#{TABLE_NAME}_100;
        CREATE TABLE IF NOT EXISTS #{TABLE_NAME} PARTITION OF p_#{TABLE_NAME} FOR VALUES IN (100);
      SQL
    end
  end
end
