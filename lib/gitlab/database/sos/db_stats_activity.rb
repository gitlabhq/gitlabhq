# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class DbStatsActivity < BaseDbStatsHandler
        FINISHED = 3
        FINALIZED = 6

        QUERIES = {
          pg_show_all_settings: <<~SQL,
            SHOW ALL;
          SQL

          pg_role_db_setting: <<~SQL,
            SELECT * FROM pg_db_role_setting;
          SQL

          read_replica_count: <<~SQL,
            SELECT COUNT(*) as replica_count
            FROM
              pg_stat_replication
            WHERE
              state = 'streaming';
          SQL

          bbm_status: <<~SQL,
            SELECT
              job_class_name,
              table_name,
              column_name,
              job_arguments
            FROM batched_background_migrations
            WHERE status NOT IN(#{FINISHED}, #{FINALIZED});
          SQL

          pg_constraints: <<~SQL,
            SELECT
              c.relname AS table_name,
              con.conname AS constraint_name,
              pg_get_constraintdef(con.oid) AS constraint_definition
            FROM
              pg_constraint con
            JOIN
              pg_class c ON c.oid = con.conrelid
            WHERE
              con.convalidated = false
            ORDER BY
              c.relname, con.conname;
          SQL

          collation_check: <<~SQL,
            SELECT collname AS collation_name,
              collversion AS version,
              pg_collation_actual_version(oid) AS actual_version
            FROM pg_collation
            WHERE collprovider = 'c';
          SQL

          pg_class_settings: <<~SQL
            SELECT * FROM pg_class;
          SQL
        }.freeze

        def run
          QUERIES.each do |name, query|
            result = execute_query(query)
            write_to_csv(name, result)
          end
        end
      end
    end
  end
end
