# frozen_string_literal: true

class AddIndexTypeToPostgresIndexesView < ActiveRecord::Migration[6.1]
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
        JOIN pg_indexes ON i.relname = pg_indexes.indexname
        JOIN pg_am a ON i.relam = a.oid
      WHERE pg_namespace.nspname <> 'pg_catalog'::name AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name]));
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_indexes;

      CREATE VIEW postgres_indexes AS
      SELECT (((pg_namespace.nspname)::text || '.'::text) || (pg_class.relname)::text) AS identifier,
         pg_index.indexrelid,
         pg_namespace.nspname AS schema,
         pg_class.relname AS name,
         pg_indexes.tablename,
         pg_index.indisunique AS "unique",
         pg_index.indisvalid AS valid_index,
         pg_class.relispartition AS partitioned,
         pg_index.indisexclusion AS exclusion,
         (pg_index.indexprs IS NOT NULL) AS expression,
         (pg_index.indpred IS NOT NULL) AS partial,
         pg_indexes.indexdef AS definition,
         pg_relation_size((pg_class.oid)::regclass) AS ondisk_size_bytes
        FROM (((pg_index
          JOIN pg_class ON ((pg_class.oid = pg_index.indexrelid)))
          JOIN pg_namespace ON ((pg_class.relnamespace = pg_namespace.oid)))
          JOIN pg_indexes ON ((pg_class.relname = pg_indexes.indexname)))
       WHERE ((pg_namespace.nspname <> 'pg_catalog'::name) AND (pg_namespace.nspname = ANY (ARRAY["current_schema"(), 'gitlab_partitions_dynamic'::name, 'gitlab_partitions_static'::name])));
    SQL
  end
end
