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
        SELECT id, created_at, updated_at, finished_at, started_at, status, job_class_name
        FROM batched_background_migrations
        WHERE job_class_name = $1::text
        SQL

        pg_client.exec_params(query, [job_class_name])
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
