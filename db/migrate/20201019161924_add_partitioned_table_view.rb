# frozen_string_literal: true

class AddPartitionedTableView < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_partitioned_tables AS
      SELECT
        pg_namespace.nspname::text || '.'::text || pg_class.relname::text AS identifier,
        pg_class.oid AS oid,
        pg_namespace.nspname AS schema,
        pg_class.relname AS name,
        CASE partitioned_tables.partstrat
        WHEN 'l' THEN 'list'
        WHEN 'r' THEN 'range'
        WHEN 'h' THEN 'hash'
        END as strategy,
        array_agg(pg_attribute.attname) as key_columns
        FROM (
          SELECT
            partrelid,
            partstrat,
            unnest(partattrs) as column_position
          FROM pg_partitioned_table
        ) partitioned_tables
        INNER JOIN pg_class
        ON partitioned_tables.partrelid = pg_class.oid
        INNER JOIN pg_namespace
        ON pg_class.relnamespace = pg_namespace.oid
        INNER JOIN pg_attribute
        ON pg_attribute.attrelid = pg_class.oid
        AND pg_attribute.attnum = partitioned_tables.column_position
        WHERE pg_namespace.nspname = current_schema()
        GROUP BY identifier, pg_class.oid, schema, name, strategy;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_partitioned_tables
    SQL
  end
end
