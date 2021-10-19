# frozen_string_literal: true

class FixDoubleEntriesInPostgresIndexView < Gitlab::Database::Migration[1.0]
  def up
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_indexes;

      CREATE VIEW postgres_indexes AS
      SELECT (pg_namespace.nspname::text || '.'::text) || i.relname::text AS identifier,
        pg_index.indexrelid,
        pg_namespace.nspname AS schema,
        i.relname AS name,
        pg_indexes.tablename,
        a.amname AS type,
        pg_index.indisunique AS "unique",
        pg_index.indisvalid AS valid_index,
        i.relispartition AS partitioned,
        pg_index.indisexclusion AS exclusion,
        pg_index.indexprs IS NOT NULL AS expression,
        pg_index.indpred IS NOT NULL AS partial,
        pg_indexes.indexdef AS definition,
        pg_relation_size(i.oid::regclass) AS ondisk_size_bytes
      FROM pg_index
        JOIN pg_class i ON i.oid = pg_index.indexrelid
        JOIN pg_namespace ON i.relnamespace = pg_namespace.oid
        JOIN pg_indexes ON i.relname = pg_indexes.indexname AND pg_namespace.nspname = pg_indexes.schemaname
        JOIN pg_am a ON i.relam = a.oid
      WHERE pg_namespace.nspname <> 'pg_catalog'::name AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name]));
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_indexes;

      CREATE VIEW postgres_indexes AS
      SELECT (pg_namespace.nspname::text || '.'::text) || i.relname::text AS identifier,
        pg_index.indexrelid,
        pg_namespace.nspname AS schema,
        i.relname AS name,
        pg_indexes.tablename,
        a.amname AS type,
        pg_index.indisunique AS "unique",
        pg_index.indisvalid AS valid_index,
        i.relispartition AS partitioned,
        pg_index.indisexclusion AS exclusion,
        pg_index.indexprs IS NOT NULL AS expression,
        pg_index.indpred IS NOT NULL AS partial,
        pg_indexes.indexdef AS definition,
        pg_relation_size(i.oid::regclass) AS ondisk_size_bytes
      FROM pg_index
        JOIN pg_class i ON i.oid = pg_index.indexrelid
        JOIN pg_namespace ON i.relnamespace = pg_namespace.oid
        JOIN pg_indexes ON i.relname = pg_indexes.indexname
        JOIN pg_am a ON i.relam = a.oid
      WHERE pg_namespace.nspname <> 'pg_catalog'::name AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name]));
    SQL
  end
end
