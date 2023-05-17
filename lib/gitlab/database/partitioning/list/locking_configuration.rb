# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module List
        class LockingConfiguration
          attr_reader :migration_context

          def initialize(migration_context, table_locking_order:)
            @migration_context = migration_context
            @table_locking_order = table_locking_order.map(&:to_s)
            assert_table_names_unqualified!(@table_locking_order)
          end

          def locking_statement_for(tables)
            tables_to_lock = locking_order_for(tables)

            return if tables_to_lock.empty?

            table_names = tables_to_lock.map { |name| migration_context.quote_table_name(name) }.join(', ')

            <<~SQL
              LOCK #{table_names} IN ACCESS EXCLUSIVE MODE
            SQL
          end

          # Sorts and subsets `tables` to the tables that were explicitly requested for locking
          # in the order that that locking was requested.
          def locking_order_for(tables)
            tables = Array.wrap(tables)
            assert_table_names_unqualified!(tables)

            @table_locking_order.intersection(tables.map(&:to_s))
          end

          def lock_timing_configuration
            iterations = Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION
            aggressive_iterations = Array.new(5) { [10.seconds, 1.minute] }

            iterations + aggressive_iterations
          end

          def with_lock_retries(&block)
            lock_args = {
              raise_on_exhaustion: true,
              timing_configuration: lock_timing_configuration
            }

            migration_context.with_lock_retries(**lock_args, &block)
          end

          private

          def assert_table_names_unqualified!(table_names)
            tables = Array.wrap(table_names).select { |name| name.to_s.include?('.') }
            return if tables.empty?

            raise ArgumentError, "All table names must be unqualified, but #{tables.join(', ')} include schema"
          end
        end
      end
    end
  end
end
