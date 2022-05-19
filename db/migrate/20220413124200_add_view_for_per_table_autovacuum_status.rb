# frozen_string_literal: true

class AddViewForPerTableAutovacuumStatus < Gitlab::Database::Migration[1.0]
  def up
    execute <<~SQL
      DROP VIEW IF EXISTS postgres_autovacuum_activity;
      DROP FUNCTION IF EXISTS postgres_pg_stat_activity_autovacuum;

      CREATE FUNCTION postgres_pg_stat_activity_autovacuum() RETURNS SETOF pg_catalog.pg_stat_activity AS
      $$
        SELECT *
        FROM pg_stat_activity
        WHERE datname = current_database()
          AND state = 'active'
          AND backend_type = 'autovacuum worker'
      $$
      LANGUAGE sql
      VOLATILE
      SECURITY DEFINER
      SET search_path = 'pg_catalog', 'pg_temp';

      CREATE VIEW postgres_autovacuum_activity AS
        WITH processes as
          (
            SELECT query, query_start, (regexp_matches(query, '^autovacuum: VACUUM (\w+)\.(\w+)')) as matches
            FROM postgres_pg_stat_activity_autovacuum()
            WHERE query ~* '^autovacuum: VACUUM \w+\.\w+'
          )
        SELECT matches[1] || '.' || matches[2] as table_identifier,
              matches[1] as schema,
              matches[2] as table,
              query_start as vacuum_start
        FROM processes;

      COMMENT ON VIEW postgres_autovacuum_activity IS 'Contains information about PostgreSQL backends currently performing autovacuum operations on the tables indicated here.';
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS postgres_autovacuum_activity;
      DROP FUNCTION IF EXISTS postgres_pg_stat_activity_autovacuum;
    SQL
  end
end
