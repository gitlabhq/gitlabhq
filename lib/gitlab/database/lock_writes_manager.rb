# frozen_string_literal: true

module Gitlab
  module Database
    class LockWritesManager
      TRIGGER_FUNCTION_NAME = 'gitlab_schema_prevent_write'

      # Triggers to block INSERT / UPDATE / DELETE
      # Triggers on TRUNCATE are not added to the information_schema.triggers
      # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
      EXPECTED_TRIGGER_RECORD_COUNT = 3

      def self.tables_to_lock(connection)
        Gitlab::Database::GitlabSchema.tables_to_schema.each do |table_name, schema_name|
          yield table_name, schema_name
        end

        Gitlab::Database::SharedModel.using_connection(connection) do
          Postgresql::DetachedPartition.find_each do |detached_partition|
            yield detached_partition.fully_qualified_table_name, detached_partition.table_schema
          end
        end
      end

      def initialize(table_name:, connection:, database_name:, with_retries: true, logger: nil, dry_run: false)
        @table_name = table_name
        @connection = connection
        @database_name = database_name
        @logger = logger
        @dry_run = dry_run
        @with_retries = with_retries

        @table_name_without_schema = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils
          .extract_schema_qualified_name(table_name)
          .identifier
      end

      def table_locked_for_writes?
        query = <<~SQL
            SELECT COUNT(*) from information_schema.triggers
            WHERE event_object_table = '#{table_name_without_schema}'
            AND trigger_name = '#{write_trigger_name}'
        SQL

        connection.select_value(query) == EXPECTED_TRIGGER_RECORD_COUNT
      end

      def lock_writes
        if table_locked_for_writes?
          logger&.info "Skipping lock_writes, because #{table_name} is already locked for writes"
          return
        end

        logger&.info "Database: '#{database_name}', Table: '#{table_name}': Lock Writes".color(:yellow)
        sql_statement = <<~SQL
          CREATE TRIGGER #{write_trigger_name}
            BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE
            ON #{table_name}
            FOR EACH STATEMENT EXECUTE FUNCTION #{TRIGGER_FUNCTION_NAME}();
        SQL

        execute_sql_statement(sql_statement)
      end

      def unlock_writes
        logger&.info "Database: '#{database_name}', Table: '#{table_name}': Allow Writes".color(:green)
        sql_statement = <<~SQL
          DROP TRIGGER IF EXISTS #{write_trigger_name} ON #{table_name};
        SQL

        execute_sql_statement(sql_statement)
      end

      private

      attr_reader :table_name, :connection, :database_name, :logger, :dry_run, :table_name_without_schema, :with_retries

      def execute_sql_statement(sql)
        if dry_run
          logger&.info sql
        elsif with_retries
          raise "Cannot call lock_retries_helper if a transaction is already open" if connection.transaction_open?

          run_with_retries(connection) do
            connection.execute(sql)
          end
        else
          connection.execute(sql)
        end
      end

      def run_with_retries(connection, &block)
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
          connection: connection,
          allow_savepoints: false # this causes the WithLockRetries to fail if sub-transaction has been detected.
        ).run(&block)
      end

      def write_trigger_name
        "gitlab_schema_write_trigger_for_#{table_name_without_schema}"
      end
    end
  end
end
