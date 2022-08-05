# frozen_string_literal: true

module Gitlab
  module Database
    class LockWritesManager
      TRIGGER_FUNCTION_NAME = 'gitlab_schema_prevent_write'

      def initialize(table_name:, connection:, database_name:, logger: nil)
        @table_name = table_name
        @connection = connection
        @database_name = database_name
        @logger = logger
      end

      def lock_writes
        logger&.info "Database: '#{database_name}', Table: '#{table_name}': Lock Writes".color(:yellow)
        sql = <<-SQL
          DROP TRIGGER IF EXISTS #{write_trigger_name(table_name)} ON #{table_name};
          CREATE TRIGGER #{write_trigger_name(table_name)}
            BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE
            ON #{table_name}
            FOR EACH STATEMENT EXECUTE FUNCTION #{TRIGGER_FUNCTION_NAME}();
        SQL

        with_retries(connection) do
          connection.execute(sql)
        end
      end

      def unlock_writes
        logger&.info "Database: '#{database_name}', Table: '#{table_name}': Allow Writes".color(:green)
        sql = <<-SQL
          DROP TRIGGER IF EXISTS #{write_trigger_name(table_name)} ON #{table_name}
        SQL

        with_retries(connection) do
          connection.execute(sql)
        end
      end

      private

      attr_reader :table_name, :connection, :database_name, :logger

      def with_retries(connection, &block)
        with_statement_timeout_retries do
          with_lock_retries(connection) do
            yield
          end
        end
      end

      def with_statement_timeout_retries(times = 5)
        current_iteration = 1
        begin
          yield
        rescue ActiveRecord::QueryCanceled => err # rubocop:disable Database/RescueQueryCanceled
          if current_iteration <= times
            current_iteration += 1
            retry
          else
            raise err
          end
        end
      end

      def with_lock_retries(connection, &block)
        Gitlab::Database::WithLockRetries.new(
          klass: "gitlab:db:lock_writes",
          logger: logger || Gitlab::AppLogger,
          connection: connection
        ).run(&block)
      end

      def write_trigger_name(table_name)
        "gitlab_schema_write_trigger_for_#{table_name}"
      end
    end
  end
end
