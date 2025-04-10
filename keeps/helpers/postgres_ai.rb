# frozen_string_literal: true

module Keeps
  module Helpers
    class PostgresAi
      Error = Class.new(StandardError)

      def initialize
        raise Error, "No credentials supplied" unless connection_string.present? && password.present?
      end

      def fetch_background_migration_status(job_class_name)
        query = <<~SQL
        SELECT id, created_at, updated_at, finished_at, started_at, status, job_class_name,
        gitlab_schema, total_tuple_count
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

      def fetch_postgres_table_size(table_name)
        query = <<~SQL
          SELECT
            identifier,
            schema_name,
            table_name,
            total_size,
            table_size,
            index_size,
            size_in_bytes,
            CASE
              WHEN size_in_bytes < 10 * 1024^3 THEN 'small'
              WHEN size_in_bytes < 50 * 1024^3 THEN 'medium'
              WHEN size_in_bytes < 100 * 1024^3 THEN 'large'
              ELSE 'over_limit'
            END AS classification
          FROM postgres_table_sizes
          WHERE table_name = $1::text
        SQL

        pg_client.exec_params(query, [table_name])
      end

      def table_has_data?(table_name)
        table_name_quoted = pg_client.quote_ident(table_name)
        query = "SELECT EXISTS (SELECT 1 FROM #{table_name_quoted} LIMIT 1)"

        pg_client.exec_params(query)
      rescue PG::UndefinedTable
        false
      end

      private

      def connection_string
        ENV["POSTGRES_AI_CONNECTION_STRING"]
      end

      def password
        ENV["POSTGRES_AI_PASSWORD"]
      end

      def pg_client
        @pg_client ||= PG.connect(connection_string, password: password)
      end
    end
  end
end
