# frozen_string_literal: true

class UpdatePostgresTableSizesView < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_table_sizes;

      CREATE OR REPLACE VIEW postgres_table_sizes AS
      SELECT
          schemaname || '.' || relname AS identifier,
          schemaname AS schema_name,
          relname AS table_name,
          pg_size_pretty(total_bytes) AS total_size,
          pg_size_pretty(table_bytes) AS table_size,
          pg_size_pretty(index_bytes) AS index_size,
          pg_size_pretty(toast_bytes) AS toast_size,
          pg_size_pretty(total_bytes - table_bytes - index_bytes - toast_bytes) AS auxiliary_size,
          total_bytes AS size_in_bytes
      FROM (
          SELECT
              schemaname,
              relname,
              pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) AS total_bytes,
              pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) AS table_bytes,
              pg_indexes_size(quote_ident(schemaname) || '.' || quote_ident(relname)) AS index_bytes,
              pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) -
              pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) -
              pg_indexes_size(quote_ident(schemaname) || '.' || quote_ident(relname)) AS toast_bytes
          FROM pg_stat_user_tables
          WHERE pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) IS NOT NULL
      ) t
      ORDER BY total_bytes DESC;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_table_sizes;

      CREATE VIEW postgres_table_sizes AS
      SELECT
          (((schemaname)::text || '.'::text) || (relname)::text) AS identifier,
          schemaname AS schema_name,
          relname AS table_name,
          pg_size_pretty(pg_total_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass)) AS total_size,
          pg_size_pretty(pg_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass)) AS table_size,
          pg_size_pretty((pg_total_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass) - pg_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass))) AS index_size,
          pg_total_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass) AS size_in_bytes
      FROM pg_stat_user_tables
      WHERE (pg_total_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass) IS NOT NULL)
      ORDER BY (pg_total_relation_size((((quote_ident((schemaname)::text) || '.'::text) || quote_ident((relname)::text)))::regclass)) DESC;
    SQL
  end
end
