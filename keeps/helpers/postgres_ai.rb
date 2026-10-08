# frozen_string_literal: true

module Keeps
  module Helpers
    class PostgresAi
      Error = Class.new(StandardError)

      CONNECTION_STRING_ENV = 'POSTGRES_AI_CONNECTION_STRING'
      PASSWORD_ENV = 'POSTGRES_AI_PASSWORD'

      def self.available?
        ENV[CONNECTION_STRING_ENV].present? && ENV[PASSWORD_ENV].present?
      end

      def initialize
        raise Error, "No credentials supplied" unless self.class.available?
      end

      def fetch_background_migration_status(job_class_name)
        query = <<~SQL
        SELECT id, created_at, updated_at, finished_at, started_at, status, job_class_name,
        gitlab_schema, total_tuple_count, table_name, column_name, job_arguments
        FROM batched_background_migrations
        WHERE job_class_name = $1::text
        SQL

        pg_client.exec_params(query, [job_class_name])
      end

      def fetch_migrated_tuple_count(batched_background_migration_id)
        query = <<~SQL
          SELECT SUM("batched_background_migration_jobs"."batch_size")
          FROM "batched_background_migration_jobs"
          WHERE "batched_background_migration_jobs"."batched_background_migration_id" = #{batched_background_migration_id}
          AND ("batched_background_migration_jobs"."status" IN (3))
        SQL

        pg_client.exec_params(query)
      end

      # Returns at most one row: the relation whose size classifies the dictionary table.
      #
      # Every dictionary table lives in the public schema, so the table itself is always a
      # candidate. A partitioned table has no storage of its own (its row in the view, if any,
      # reports zero bytes) and the dictionary defines its size as the size of its largest
      # partition, so when the public relation is partitioned its partitions are candidates too.
      # Partitions are resolved through pg_inherits rather than a name prefix: a sibling table
      # that merely shares the prefix (an `_archive` copy, for example) must not be counted.
      def fetch_postgres_table_size(table_name)
        query = <<~SQL
          WITH relations AS (
            SELECT 'public'::text AS schema_name, $1::text AS table_name, false AS is_partition
            UNION ALL
            SELECT child_namespace.nspname::text, child.relname::text, true
            FROM pg_inherits
            INNER JOIN pg_class parent ON parent.oid = pg_inherits.inhparent
            INNER JOIN pg_namespace parent_namespace ON parent_namespace.oid = parent.relnamespace
            INNER JOIN pg_class child ON child.oid = pg_inherits.inhrelid
            INNER JOIN pg_namespace child_namespace ON child_namespace.oid = child.relnamespace
            WHERE parent.relname = $1::text
              AND parent_namespace.nspname = 'public'
              AND parent.relkind = 'p'
          )
          SELECT
            size_row.identifier,
            size_row.size_in_bytes,
            relations.is_partition,
            CASE
              WHEN size_row.size_in_bytes < 10 * 1024^3 THEN 'small'
              WHEN size_row.size_in_bytes < 50 * 1024^3 THEN 'medium'
              WHEN size_row.size_in_bytes < 100 * 1024^3 THEN 'large'
              ELSE 'over_limit'
            END AS classification
          FROM relations
          CROSS JOIN LATERAL (
            SELECT identifier, size_in_bytes
            FROM postgres_table_sizes
            WHERE schema_name = relations.schema_name
              AND table_name = relations.table_name
            LIMIT 1
          ) size_row
          ORDER BY size_row.size_in_bytes DESC, relations.is_partition ASC, size_row.identifier ASC
          LIMIT 1
        SQL

        pg_client.exec_params(query, [table_name])
      end

      # The function name must match Gitlab::Database::LockWritesManager::TRIGGER_FUNCTION_NAME.
      # Such a trigger means the connected database is not the authoritative one for this table
      # (writes are locked post-decomposition), so its size there says nothing about the real
      # table. Matching by trigger function, not trigger name: names derived from long table
      # names get truncated to 63 bytes by PostgreSQL. The query is scoped to the public schema,
      # where every dictionary table lives: a same-named relation in another schema (clone
      # leftover, for example) must not decide a skip. fetch_postgres_table_size starts from the
      # same public relation and only widens to partitions that pg_inherits attributes to it.
      def table_write_locked?(table_name)
        query = <<~SQL
          SELECT EXISTS (
            SELECT 1
            FROM pg_trigger
            INNER JOIN pg_class ON pg_class.oid = pg_trigger.tgrelid
            INNER JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
            INNER JOIN pg_proc ON pg_proc.oid = pg_trigger.tgfoid
            WHERE pg_class.relname = $1::text
              AND pg_namespace.nspname = 'public'
              AND pg_proc.proname = 'gitlab_schema_prevent_write'
          )
        SQL

        result = pg_client.exec_params(query, [table_name])

        Gitlab::Utils.to_boolean(result.first.fetch('exists'))
      end

      def pg_client
        @pg_client ||= PG.connect(connection_string, password: password)
      end

      def close
        @pg_client&.close
        @pg_client = nil
      end

      private

      def connection_string
        ENV[CONNECTION_STRING_ENV]
      end

      def password
        ENV[PASSWORD_ENV]
      end
    end
  end
end
