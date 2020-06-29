# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module TableManagementHelpers
        include ::Gitlab::Database::SchemaHelpers
        include ::Gitlab::Database::DynamicModelHelpers
        include ::Gitlab::Database::Migrations::BackgroundMigrationHelpers

        ALLOWED_TABLES = %w[audit_events].freeze
        ERROR_SCOPE = 'table partitioning'

        MIGRATION_CLASS_NAME = "::#{module_parent_name}::BackfillPartitionedTable"
        BATCH_INTERVAL = 2.minutes.freeze
        BATCH_SIZE = 50_000

        # Creates a partitioned copy of an existing table, using a RANGE partitioning strategy on a timestamp column.
        # One partition is created per month between the given `min_date` and `max_date`.
        #
        # A copy of the original table is required as PG currently does not support partitioning existing tables.
        #
        # Example:
        #
        #   partition_table_by_date :audit_events, :created_at, min_date: Date.new(2020, 1), max_date: Date.new(2020, 6)
        #
        # Options are:
        #   :min_date - a date specifying the lower bounds of the partition range
        #   :max_date - a date specifying the upper bounds of the partitioning range, defaults to today + 1 month
        #
        # Unless min_date is specified explicitly, we default to
        # 1. The minimum value for the partitioning column in the table
        # 2. If no data is present yet, the current month
        def partition_table_by_date(table_name, column_name, min_date: nil, max_date: nil)
          assert_table_is_allowed(table_name)

          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          max_date ||= Date.today + 1.month

          min_date ||= connection.select_one(<<~SQL)['minimum'] || max_date - 1.month
            SELECT date_trunc('MONTH', MIN(#{column_name})) AS minimum
            FROM #{table_name}
          SQL

          raise "max_date #{max_date} must be greater than min_date #{min_date}" if min_date >= max_date

          primary_key = connection.primary_key(table_name)
          raise "primary key not defined for #{table_name}" if primary_key.nil?

          partition_column = find_column_definition(table_name, column_name)
          raise "partition column #{column_name} does not exist on #{table_name}" if partition_column.nil?

          partitioned_table_name = make_partitioned_table_name(table_name)

          create_range_partitioned_copy(table_name, partitioned_table_name, partition_column, primary_key)
          create_daterange_partitions(partitioned_table_name, partition_column.name, min_date, max_date)
          create_trigger_to_sync_tables(table_name, partitioned_table_name, primary_key)
          enqueue_background_migration(table_name, partitioned_table_name, primary_key)
        end

        # Clean up a partitioned copy of an existing table. This deletes the partitioned table and all partitions.
        #
        # Example:
        #
        #   drop_partitioned_table_for :audit_events
        #
        def drop_partitioned_table_for(table_name)
          assert_table_is_allowed(table_name)
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          with_lock_retries do
            trigger_name = make_sync_trigger_name(table_name)
            drop_trigger(table_name, trigger_name)
          end

          function_name = make_sync_function_name(table_name)
          drop_function(function_name)

          partitioned_table_name = make_partitioned_table_name(table_name)
          drop_table(partitioned_table_name)
        end

        def create_hash_partitions(table_name, number_of_partitions)
          transaction do
            (0..number_of_partitions - 1).each do |partition|
              decimals = Math.log10(number_of_partitions).ceil
              suffix = "%0#{decimals}d" % partition
              partition_name = "#{table_name}_#{suffix}"
              schema = Gitlab::Database::STATIC_PARTITIONS_SCHEMA

              execute(<<~SQL)
                CREATE TABLE #{schema}.#{partition_name}
                PARTITION OF #{table_name}
                FOR VALUES WITH (MODULUS #{number_of_partitions}, REMAINDER #{partition});
              SQL
            end
          end
        end

        private

        def assert_table_is_allowed(table_name)
          return if ALLOWED_TABLES.include?(table_name.to_s)

          raise "partitioning helpers are in active development, and #{table_name} is not allowed for use, " \
            "for more information please contact the database team"
        end

        def make_partitioned_table_name(table)
          tmp_table_name("#{table}_part")
        end

        def make_sync_function_name(table)
          object_name(table, 'table_sync_function')
        end

        def make_sync_trigger_name(table)
          object_name(table, 'table_sync_trigger')
        end

        def find_column_definition(table, column)
          connection.columns(table).find { |c| c.name == column.to_s }
        end

        def create_range_partitioned_copy(source_table_name, partitioned_table_name, partition_column, primary_key)
          if table_exists?(partitioned_table_name)
            # rubocop:disable Gitlab/RailsLogger
            Rails.logger.warn "Partitioned table not created because it already exists" \
              " (this may be due to an aborted migration or similar): table_name: #{partitioned_table_name} "
            # rubocop:enable Gitlab/RailsLogger
            return
          end

          tmp_column_name = object_name(partition_column.name, 'partition_key')
          transaction do
            execute(<<~SQL)
              CREATE TABLE #{partitioned_table_name} (
                LIKE #{source_table_name} INCLUDING ALL EXCLUDING INDEXES,
                #{tmp_column_name} #{partition_column.sql_type} NOT NULL,
                PRIMARY KEY (#{[primary_key, tmp_column_name].join(", ")})
              ) PARTITION BY RANGE (#{tmp_column_name})
            SQL

            remove_column(partitioned_table_name, partition_column.name)
            rename_column(partitioned_table_name, tmp_column_name, partition_column.name)
            change_column_default(partitioned_table_name, primary_key, nil)

            if column_of_type?(partitioned_table_name, primary_key, :integer)
              # Default to int8 primary keys to prevent overflow
              change_column(partitioned_table_name, primary_key, :bigint)
            end
          end
        end

        def column_of_type?(table_name, column, type)
          find_column_definition(table_name, column).type == type
        end

        def create_daterange_partitions(table_name, column_name, min_date, max_date)
          min_date = min_date.beginning_of_month.to_date
          max_date = max_date.next_month.beginning_of_month.to_date

          upper_bound = to_sql_date_literal(min_date)
          create_range_partition_safely("#{table_name}_000000", table_name, 'MINVALUE', upper_bound)

          while min_date < max_date
            partition_name = "#{table_name}_#{min_date.strftime('%Y%m')}"
            next_date = min_date.next_month
            lower_bound = to_sql_date_literal(min_date)
            upper_bound = to_sql_date_literal(next_date)

            create_range_partition_safely(partition_name, table_name, lower_bound, upper_bound)
            min_date = next_date
          end
        end

        def to_sql_date_literal(date)
          connection.quote(date.strftime('%Y-%m-%d'))
        end

        def create_range_partition_safely(partition_name, table_name, lower_bound, upper_bound)
          if table_exists?(table_for_range_partition(partition_name))
            # rubocop:disable Gitlab/RailsLogger
            Rails.logger.warn "Partition not created because it already exists" \
              " (this may be due to an aborted migration or similar): partition_name: #{partition_name}"
            # rubocop:enable Gitlab/RailsLogger
            return
          end

          create_range_partition(partition_name, table_name, lower_bound, upper_bound)
        end

        def create_trigger_to_sync_tables(source_table_name, partitioned_table_name, unique_key)
          function_name = make_sync_function_name(source_table_name)
          trigger_name = make_sync_trigger_name(source_table_name)

          with_lock_retries do
            create_sync_function(function_name, partitioned_table_name, unique_key)
            create_comment('FUNCTION', function_name, "Partitioning migration: table sync for #{source_table_name} table")

            create_sync_trigger(source_table_name, trigger_name, function_name)
          end
        end

        def create_sync_function(name, partitioned_table_name, unique_key)
          if function_exists?(name)
            # rubocop:disable Gitlab/RailsLogger
            Rails.logger.warn "Partitioning sync function not created because it already exists" \
              " (this may be due to an aborted migration or similar): function name: #{name}"
            # rubocop:enable Gitlab/RailsLogger
            return
          end

          delimiter = ",\n    "
          column_names = connection.columns(partitioned_table_name).map(&:name)
          set_statements = build_set_statements(column_names, unique_key)
          insert_values = column_names.map { |name| "NEW.#{name}" }

          create_trigger_function(name, replace: false) do
            <<~SQL
              IF (TG_OP = 'DELETE') THEN
                DELETE FROM #{partitioned_table_name} where #{unique_key} = OLD.#{unique_key};
              ELSIF (TG_OP = 'UPDATE') THEN
                UPDATE #{partitioned_table_name}
                SET #{set_statements.join(delimiter)}
                WHERE #{partitioned_table_name}.#{unique_key} = NEW.#{unique_key};
              ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO #{partitioned_table_name} (#{column_names.join(delimiter)})
                VALUES (#{insert_values.join(delimiter)});
              END IF;
              RETURN NULL;
            SQL
          end
        end

        def build_set_statements(column_names, unique_key)
          column_names.reject { |name| name == unique_key }.map { |name| "#{name} = NEW.#{name}" }
        end

        def create_sync_trigger(table_name, trigger_name, function_name)
          if trigger_exists?(table_name, trigger_name)
            # rubocop:disable Gitlab/RailsLogger
            Rails.logger.warn "Partitioning sync trigger not created because it already exists" \
              " (this may be due to an aborted migration or similar): trigger name: #{trigger_name}"
            # rubocop:enable Gitlab/RailsLogger
            return
          end

          create_trigger(table_name, trigger_name, function_name, fires: 'AFTER INSERT OR UPDATE OR DELETE')
        end

        def enqueue_background_migration(source_table_name, partitioned_table_name, source_key)
          source_model = define_batchable_model(source_table_name)

          queue_background_migration_jobs_by_range_at_intervals(
            source_model,
            MIGRATION_CLASS_NAME,
            BATCH_INTERVAL,
            batch_size: BATCH_SIZE,
            other_job_arguments: [source_table_name.to_s, partitioned_table_name, source_key])
        end
      end
    end
  end
end
