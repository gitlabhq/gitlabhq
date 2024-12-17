# frozen_string_literal: true

class AddPostgresTableSizesView < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_table_sizes AS
      SELECT
          schemaname || '.' || relname as identifier,
          schemaname as schema_name,
          relname as table_name,
          pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname))) as total_size,
          pg_size_pretty(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname))) as table_size,
          pg_size_pretty(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) -
                        pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname))) as index_size,
          pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) as size_in_bytes
      FROM pg_stat_user_tables
      WHERE pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) IS NOT NULL
      ORDER BY pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(relname)) DESC;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW postgres_table_sizes
    SQL
  end
end
