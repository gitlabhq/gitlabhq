# frozen_string_literal: true

class ExtendPostgresIndexesView < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(<<~SQL)
      DROP VIEW postgres_indexes;

      CREATE VIEW postgres_indexes AS
      SELECT (pg_namespace.nspname::text || '.'::text) || pg_class.relname::text AS identifier,
        pg_index.indexrelid,
        pg_namespace.nspname AS schema,
        pg_class.relname AS name,
        pg_index.indisunique AS "unique",
        pg_index.indisvalid AS valid_index,
        pg_class.relispartition AS partitioned,
        pg_index.indisexclusion AS exclusion,
        pg_index.indexprs IS NOT NULL as expression,
        pg_index.indpred IS NOT NULL as partial,
        pg_indexes.indexdef AS definition,
        pg_relation_size(pg_class.oid::regclass) AS ondisk_size_bytes
      FROM pg_index
        JOIN pg_class ON pg_class.oid = pg_index.indexrelid
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        JOIN pg_indexes ON pg_class.relname = pg_indexes.indexname
      WHERE pg_namespace.nspname <> 'pg_catalog'::name
        AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name]));
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW postgres_indexes;

      CREATE VIEW postgres_indexes AS
      SELECT (pg_namespace.nspname::text || '.'::text) || pg_class.relname::text AS identifier,
        pg_index.indexrelid,
        pg_namespace.nspname AS schema,
        pg_class.relname AS name,
        pg_index.indisunique AS "unique",
        pg_index.indisvalid AS valid_index,
        pg_class.relispartition AS partitioned,
        pg_index.indisexclusion AS exclusion,
        pg_indexes.indexdef AS definition,
        pg_relation_size(pg_class.oid::regclass) AS ondisk_size_bytes
      FROM pg_index
        JOIN pg_class ON pg_class.oid = pg_index.indexrelid
        JOIN pg_namespace ON pg_class.relnamespace = pg_namespace.oid
        JOIN pg_indexes ON pg_class.relname = pg_indexes.indexname
      WHERE pg_namespace.nspname <> 'pg_catalog'::name
        AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name]));
    SQL
  end
end
