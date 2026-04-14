# frozen_string_literal: true

class AddPostgresTriggersView < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE VIEW postgres_triggers AS
      SELECT
        CONCAT(nsp.nspname, '.', rel.relname, '.', trgr.tgname) AS identifier,
        trgr.tgname AS trigger_name,
        rel.relname AS table_name,
        nsp.nspname AS schema_name,
        proc.proname AS function_name
      FROM pg_catalog.pg_trigger trgr
        INNER JOIN pg_catalog.pg_class rel
          ON trgr.tgrelid = rel.oid
        INNER JOIN pg_catalog.pg_namespace nsp
          ON nsp.oid = rel.relnamespace
        LEFT JOIN pg_catalog.pg_proc proc
          ON trgr.tgfoid = proc.oid
      WHERE NOT trgr.tgisinternal
        AND nsp.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast');
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW IF EXISTS postgres_triggers;
    SQL
  end
end
