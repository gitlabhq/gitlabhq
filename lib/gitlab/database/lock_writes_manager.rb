# frozen_string_literal: true

module Gitlab
  module Database
    class LockWritesManager
      TRIGGER_FUNCTION_NAME = 'gitlab_schema_prevent_write'

      # Triggers to block INSERT / UPDATE / DELETE
      # Triggers on TRUNCATE are not added to the information_schema.triggers
      # See https://www.postgresql.org/message-id/16934.1568989957%40sss.pgh.pa.us
      EXPECTED_TRIGGER_RECORD_COUNT = 3

      # table_name can include schema name as a prefix. For example: 'gitlab_partitions_static.events_03',
      # otherwise, it will default to current used schema, for example 'public'.
      def initialize(table_name:, connection:, database_name:, with_retries: true, logger: nil, dry_run: false)
        @table_name = table_name.to_s
        @connection = connection
        @database_name = database_name
        @logger = logger
        @dry_run = dry_run
        @with_retries = with_retries

        @table_name_without_schema = ActiveRecord::ConnectionAdapters::PostgreSQL::Utils
          .extract_schema_qualified_name(table_name.to_s)
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
        unless table_exist?
          logger&.info "Skipping lock_writes, because #{table_name} does not exist"
          return result_hash(action: 'skipped')
        end

        if table_locked_for_writes?
          logger&.info "Skipping lock_writes, because #{table_name} is already locked for writes"
          return result_hash(action: 'skipped')
        end

        logger&.info Rainbow("Database: '#{database_name}', Table: '#{table_name}': Lock Writes").yellow
        sql_statement = <<~SQL
          CREATE TRIGGER #{write_trigger_name}
            BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE
            ON #{table_name}
            FOR EACH STATEMENT EXECUTE FUNCTION #{TRIGGER_FUNCTION_NAME}();
        SQL

        result = process_query(sql_statement, 'lock')

        result_hash(action: result)
      end

      def unlock_writes
        unless table_locked_for_writes?
          logger&.info "Skipping unlock_writes, because #{table_name} is already unlocked for writes"
          return result_hash(action: 'skipped')
        end

        logger&.info Rainbow("Database: '#{database_name}', Table: '#{table_name}': Allow Writes").green
        sql_statement = <<~SQL
          DROP TRIGGER IF EXISTS #{write_trigger_name} ON #{table_name};
        SQL

        result = process_query(sql_statement, 'unlock')

        result_hash(action: result)
      end

      private

      attr_reader :table_name, :connection, :database_name, :logger, :dry_run, :table_name_without_schema, :with_retries

      def table_exist?
        where = if table_name.include?('.')
                  schema, table = table_name.split('.')

                  "#{Arel.sql('table_name').eq(table).to_sql} AND #{Arel.sql('table_schema').eq(schema).to_sql}"
                else
                  "#{Arel.sql('table_name').eq(table_name).to_sql} AND table_schema = current_schema()"
                end

        @connection.execute("SELECT table_name FROM information_schema.tables WHERE #{where}").any?
      end

      def process_query(sql, action)
        if dry_run
          logger&.info sql
          "needs_#{action}"
        else
          execute_sql_statement(sql)
          "#{action}ed"
        end
      end

      def execute_sql_statement(sql)
        if with_retries
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

      def result_hash(action:)
        { action: action, database: database_name, table: table_name, dry_run: dry_run }
      end
    end
  end
end
