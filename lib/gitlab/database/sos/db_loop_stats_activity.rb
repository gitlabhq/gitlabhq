# frozen_string_literal: true

require 'csv'

module Gitlab
  module Database
    module Sos
      class DbLoopStatsActivity < BaseDbStatsHandler
        QUERIES = {
          pg_stat_user_tables: <<~SQL,
            SELECT now() AS timestamp, *
            FROM pg_stat_user_tables;
          SQL

          pg_stat_user_indexes: <<~SQL,
            SELECT now() AS timestamp, *
            FROM pg_stat_user_indexes;
          SQL

          pg_statio_user_tables: <<~SQL,
            SELECT now() AS timestamp, *
            FROM pg_statio_user_tables;
          SQL

          pg_statio_user_indexes: <<~SQL,
            SELECT now() AS timestamp, *
            FROM pg_statio_user_indexes;
          SQL

          table_relation_size: <<~SQL.squish,
            SELECT
              now() AS timestamp,
              n.nspname || '.' || c.relname AS "relation",
              pg_total_relation_size(c.oid) AS "total_size_bytes"
            FROM
              pg_class c
            JOIN
              pg_namespace n ON n.oid = c.relnamespace
            WHERE
              n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
            ORDER BY
              pg_total_relation_size(c.oid) DESC;
          SQL

          pg_lock_stat_activity: <<~SQL.squish
            SELECT
              now() AS timestamp,
              a.pid,
              a.usename,
              a.application_name,
              a.client_addr,
              a.backend_start,
              (now() - a.backend_start) AS backend_age,
              a.xact_start,
              (now() - a.xact_start) AS xact_age,
              a.query_start,
              (now() - a.query_start) AS query_age,
              a.state,
              a.wait_event_type,
              a.wait_event,
              a.query_id,
              a.query,
              (
                SELECT json_agg(json_build_object(
                  'locktype', l.locktype,
                  'mode', l.mode,
                  'granted', l.granted,
                  'locked_relation', l.relation::regclass
                ))
                FROM pg_locks l
                WHERE l.pid = a.pid
              ) AS locks
            FROM
              pg_stat_activity a
            WHERE
              a.pid != pg_backend_pid()
              AND a.state != 'idle'
            ORDER BY
              a.query_start DESC;
          SQL
        }.freeze

        def run
          QUERIES.each do |query_name, query|
            result = execute_query(query)
            write_to_csv(query_name, result, include_timestamp: true)
          end
        end
      end
    end
  end
end
