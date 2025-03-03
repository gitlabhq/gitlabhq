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
              a.query_start,
              a.state,
              a.wait_event_type,
              a.wait_event,
              a.query,
              l.locktype,
              l.mode,
              l.granted,
              l.relation::regclass AS locked_relation
            FROM
              pg_stat_activity a
            LEFT JOIN
              pg_locks l ON l.pid = a.pid
            WHERE
              a.state != 'idle'
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
