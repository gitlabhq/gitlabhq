# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module RequireDisableDdlTransactionForMultipleLocks
        extend ActiveSupport::Concern

        LOCK_ACQUIRING_COMMANDS = %w[ALTER CREATE DROP TRUNCATE LOCK UPDATE DELETE INSERT].freeze

        # Reference: https://www.postgresql.org/docs/current/explicit-locking.html
        LOCK_TYPES = {
          high_severity: [
            'AccessExclusiveLock',  # Conflicts with all lock modes
            'ExclusiveLock'         # Conflicts with all except ROW SHARE
          ],

          low_severity: [
            'RowShareLock',         # Conflicts with EXCLUSIVE
            'AccessShareLock'       # Conflicts with ACCESS EXCLUSIVE only
          ]
        }.freeze

        class_methods do
          def skip_require_disable_ddl_transactions!
            @skip_require_disable_ddl_transactions = true
          end

          def skip_require_disable_ddl_transactions?
            @skip_require_disable_ddl_transactions
          end
        end

        def exec_migration(connection, direction)
          return super if should_skip_check?

          # In-memory tracking structures
          statement_tracking = []
          tables_locked_up_till_now = Set.new

          begin
            # Subscribe to SQL execution to track each statement
            subscription_id = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
              event = ActiveSupport::Notifications::Event.new(*args)
              sql = event.payload[:sql].strip

              next if should_skip_sql_statement?(sql)

              newly_locked_tables = []
              if likely_to_acquire_locks?(sql)
                newly_locked_tables = check_current_locks(connection).excluding(tables_locked_up_till_now.to_a)
              end

              newly_locked_tables.each { |table| tables_locked_up_till_now.add(table) }

              # Record new statement
              current_statement = {
                number: 1 + statement_tracking.size,
                sql: sql,
                locked_tables: newly_locked_tables.uniq
              }
              statement_tracking << current_statement
            end

            # Run the migration
            super.tap do
              # After the migration completes, analyze the collected lock data
              verify_single_table_per_statement(statement_tracking)
            end
          ensure
            # Cleanup
            ActiveSupport::Notifications.unsubscribe(subscription_id) if subscription_id
          end
        end

        private

        def should_skip_check?
          return true if disable_ddl_transaction

          self.class.skip_require_disable_ddl_transactions?
        end

        def should_skip_sql_statement?(sql)
          sql.empty? ||
            sql.start_with?('SET', 'BEGIN', 'COMMIT', 'ROLLBACK') ||
            sql.include?('pg_locks') ||
            (sql.start_with?('SELECT') && sql.exclude?('FOR UPDATE') && sql.exclude?('FOR SHARE'))
        end

        def likely_to_acquire_locks?(sql)
          first_word = sql.split(' ').first&.upcase

          LOCK_ACQUIRING_COMMANDS.include?(first_word) ||
            sql.include?('FOR UPDATE') ||
            sql.include?('FOR SHARE') ||
            sql.match?(/CREATE\s+(OR\s+REPLACE\s+)?TRIGGER/i)
        end

        def check_current_locks(connection)
          # Get current locks excluding system tables and read-only locks
          low_severity_locks = LOCK_TYPES[:low_severity].map { |lock| connection.quote(lock) }.join(', ')

          locks = connection.execute(<<-SQL)
            SELECT DISTINCT relation::regclass AS table_name
            FROM pg_locks
            JOIN pg_class ON pg_locks.relation = pg_class.oid
            WHERE relation IS NOT NULL
              AND pg_class.relkind IN ('r', 'p')  -- Only regular/partitioned tables
              AND pid = pg_backend_pid()
              AND relation::regclass::text NOT LIKE 'pg_%'
              AND relation::regclass::text NOT LIKE 'information_schema.%'
              AND relation::regclass::text NOT IN ('schema_migrations', 'ar_internal_metadata')
              AND mode NOT IN (#{low_severity_locks})
          SQL

          locks.pluck('table_name').map(&:to_s).uniq
        end

        def verify_single_table_per_statement(statement_tracking)
          # Get all tables locked across all statements
          table_lock_statements = []

          statement_tracking.each do |statement|
            # Skip statements with no locks
            next if statement[:locked_tables].empty?

            # Check if this specific statement locked tables
            table_lock_statements << statement if statement[:locked_tables].any?
          end

          # Check if we have locks on multiple tables across the entire migration
          return unless table_lock_statements.many?

          error_message = ["This migration locks multiple tables across different statements:"]
          error_message << table_lock_statements.flatten.uniq.to_a.join(', ')

          error_message << "\nTables locked by each statement:"
          statement_tracking.each do |stmt|
            next if stmt[:locked_tables].empty?

            error_message << "  Statement ##{stmt[:number]}: #{stmt[:locked_tables].join(', ')}"
            error_message << "  SQL: #{stmt[:sql]}"
          end

          error_message << "\nPlease do one of the following:"
          error_message << "  - Split this migration into smaller migrations that each lock only a single table"
          error_message << "  - Disable the outer transaction by calling disable_ddl_transaction!"
          error_message <<
            "  - Disable check if you feel it is a false positive by calling skip_require_disable_ddl_transactions!"
          raise error_message.join("\n")
        end
      end
    end
  end
end
