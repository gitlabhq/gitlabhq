# frozen_string_literal: true

class AddVacuumTypeToAutovacuumStatus < Gitlab::Database::Migration[2.1]
  def up
    execute <<~SQL
      DROP VIEW IF EXISTS postgres_autovacuum_activity;

      CREATE VIEW postgres_autovacuum_activity AS
        WITH processes as
          (
            SELECT query, query_start, (regexp_matches(query, '^autovacuum: VACUUM (\\w+)\\.(\\w+)')) as matches,
            CASE WHEN (query ~~* '%wraparound)'::text) THEN true ELSE false END as wraparound_prevention
            FROM postgres_pg_stat_activity_autovacuum()
            WHERE query ~* '^autovacuum: VACUUM \\w+\\.\\w+'
          )
        SELECT matches[1] || '.' || matches[2] as table_identifier,
              matches[1] as schema,
              matches[2] as table,
              query_start as vacuum_start,
              wraparound_prevention
        FROM processes;

      COMMENT ON VIEW postgres_autovacuum_activity IS 'Contains information about PostgreSQL backends currently performing autovacuum operations on the tables indicated here.';
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS postgres_autovacuum_activity;

      CREATE VIEW postgres_autovacuum_activity AS
        WITH processes as
          (
            SELECT query, query_start, (regexp_matches(query, '^autovacuum: VACUUM (\\w+)\\.(\\w+)')) as matches
            FROM postgres_pg_stat_activity_autovacuum()
            WHERE query ~* '^autovacuum: VACUUM \\w+\\.\\w+'
          )
        SELECT matches[1] || '.' || matches[2] as table_identifier,
              matches[1] as schema,
              matches[2] as table,
              query_start as vacuum_start
        FROM processes;

      COMMENT ON VIEW postgres_autovacuum_activity IS 'Contains information about PostgreSQL backends currently performing autovacuum operations on the tables indicated here.';
    SQL
  end
end
