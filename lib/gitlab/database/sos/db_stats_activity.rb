# frozen_string_literal: true

module Gitlab
  module Database
    module Sos
      class DbStatsActivity < BaseDbStatsHandler
        FINISHED = 3
        FINALIZED = 6

        LFK_DELETED_RECORD_TABLES = %w[
          loose_foreign_keys_deleted_records
          loose_foreign_keys_user_deleted_records
          loose_foreign_keys_namespace_deleted_records
          loose_foreign_keys_project_deleted_records
          loose_foreign_keys_organization_deleted_records
        ].freeze

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

          pg_class_settings: <<~SQL,
            SELECT * FROM pg_class;
          SQL

          # Detects sequences with corrupted ownership: a sequence should only
          # ever have an automatic ('a') OWNED BY dependency, but pg_upgrade
          # can leave a spurious normal ('n') dependency pointing the sequence at an
          # unrelated table column.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/473337.
          broken_sequence_ownership: <<~SQL
            SELECT
              seq.relname AS seq_name,
              tbl.relname AS table_name,
              att.attname AS col_name,
              dep.deptype
            FROM pg_class seq
            JOIN pg_depend dep
              ON seq.oid = dep.objid
              AND dep.classid = 'pg_class'::regclass
              AND dep.refclassid = 'pg_class'::regclass
            JOIN pg_class tbl ON dep.refobjid = tbl.oid
            JOIN pg_attribute att ON tbl.oid = att.attrelid AND dep.refobjsubid = att.attnum
            WHERE seq.relkind = 'S'
              AND dep.deptype = 'n'
            ORDER BY seq.relname, tbl.relname;
          SQL
        }.merge(
          # Backlog of pending loose foreign key cleanups per source table, one query
          # (and one CSV) per deleted-records queue.
          LFK_DELETED_RECORD_TABLES.to_h do |table|
            [:"#{table}_backlog", <<~SQL]
              SELECT fully_qualified_table_name AS source_table,
                     count(*) AS pending,
                     count(*) FILTER (WHERE consume_after <= now()) AS due_now,
                     max(cleanup_attempts) AS max_attempts,
                     min(consume_after) AS oldest_consume_after
              FROM #{table}
              WHERE status = 1
              GROUP BY 1
              ORDER BY pending DESC;
            SQL
          end
        ).freeze

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
