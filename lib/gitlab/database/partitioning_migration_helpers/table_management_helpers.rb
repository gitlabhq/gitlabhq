# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module TableManagementHelpers
        include ::Gitlab::Database::SchemaHelpers
        include ::Gitlab::Database::MigrationHelpers
        include ::Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

        ALLOWED_TABLES = %w[group_audit_events project_audit_events instance_audit_events user_audit_events
          audit_events web_hook_logs merge_request_diff_files merge_request_diff_commits
          ci_runners ci_runner_machines].freeze

        ERROR_SCOPE = 'table partitioning'

        MIGRATION_CLASS_NAME = "::#{module_parent_name}::BackfillPartitionedTable"
        MIGRATION = "BackfillPartitionedTable"
        BATCH_INTERVAL = 2.minutes.freeze
        BATCH_SIZE = 50_000
        SUB_BATCH_SIZE = 2_500
        PARTITION_BUFFER = 6
        MIN_ID = 1

        # Creates a partitioned copy of an existing table, using a RANGE partitioning strategy on a int/bigint column.
        # One partition is created per partition_size between 1 and MAX(column_name). Also installs a trigger on
        # the original table to copy writes into the partitioned table. To copy over historic data from before creation
        # of the partitioned table, use the `enqueue_partitioning_data_migration` helper in a post-deploy migration.
        # Note: If the original table is empty the system creates 6 partitions in the new table.
        #
        # A copy of the original table is required as PG currently does not support partitioning existing tables.
        #
        # Example:
        #
        #   partition_table_by_int_range :merge_request_diff_commits, :merge_request_diff_id, partition_size: 500, primary_key: ['merge_request_diff_id', 'relative_order']
        #
        # Options are:
        #   :partition_size - a int specifying the partition size
        #   :primary_key - a array specifying the primary query of the new table
        #
        # Note: The system always adds a buffer of 6 partitions.
        def partition_table_by_int_range(table_name, column_name, partition_size:, primary_key:)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          assert_table_is_allowed(table_name)

          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          current_primary_key = Array.wrap(connection.primary_key(table_name))
          raise "primary key not defined for #{table_name}" if current_primary_key.blank?

          partition_column = find_column_definition(table_name, column_name)
          raise "partition column #{column_name} does not exist on #{table_name}" if partition_column.nil?

          primary_key = Array.wrap(primary_key).map(&:to_s)
          raise "the partition column must be part of the primary key" unless primary_key.include?(column_name.to_s)

          primary_key_objects = connection.columns(table_name).select { |column| primary_key.include?(column.name) }

          raise 'partition_size must be greater than 1' unless partition_size > 1

          max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
            Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
              define_batchable_model(table_name, connection: connection).maximum(column_name) || (partition_size * PARTITION_BUFFER)
            end
          end

          partitioned_table_name = make_partitioned_table_name(table_name)

          with_lock_retries do
            create_range_id_partitioned_copy(table_name, partitioned_table_name, partition_column, primary_key_objects)
            create_int_range_partitions(partitioned_table_name, partition_size, MIN_ID, max_id)
            create_trigger_to_sync_tables(table_name, partitioned_table_name, current_primary_key)
          end
        end

        # Creates a partitioned copy of an existing table, using a RANGE partitioning strategy on a timestamp column.
        # One partition is created per month between the given `min_date` and `max_date`. Also installs a trigger on
        # the original table to copy writes into the partitioned table. To copy over historic data from before creation
        # of the partitioned table, use the `enqueue_partitioning_data_migration` helper in a post-deploy migration.
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
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          assert_table_is_allowed(table_name)

          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          max_date ||= Date.today + 1.month

          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
            min_date ||= connection.select_one(<<~SQL)['minimum'] || (max_date - 1.month)
              SELECT date_trunc('MONTH', MIN(#{column_name})) AS minimum
              FROM #{table_name}
            SQL
          end

          raise "max_date #{max_date} must be greater than min_date #{min_date}" if min_date >= max_date

          primary_key = connection.primary_key(table_name)
          raise "primary key not defined for #{table_name}" if primary_key.nil?

          partition_column = find_column_definition(table_name, column_name)
          raise "partition column #{column_name} does not exist on #{table_name}" if partition_column.nil?

          partitioned_table_name = make_partitioned_table_name(table_name)

          transaction do
            create_range_partitioned_copy(table_name, partitioned_table_name, partition_column, primary_key)
            create_daterange_partitions(partitioned_table_name, partition_column.name, min_date, max_date)
          end

          with_lock_retries do
            create_trigger_to_sync_tables(table_name, partitioned_table_name, primary_key)
          end
        end

        # Creates a partitioned copy of an existing table, using a LIST partitioning strategy on a int/bigint column.
        # One partition is created per column_name value. Also installs a trigger on the original table to copy writes
        # into the partitioned table.
        # To copy over historic data from before creation of the partitioned table, use the
        # `enqueue_partitioning_data_migration` helper in a post-deploy migration.
        #
        # A copy of the original table is required as PG currently does not support partitioning existing tables.
        #
        # Example:
        #
        #   partition_table_by_list :ci_runners, :runner_type, primary_key: ['id', 'runner_type'],
        #     partition_mappings: { instance_type: 1, group_type: 2, project_type: 3 },
        #     partition_name_format: "%{partition_name}_%{table_name}",
        #     create_partitioned_table_fn: ->(name) { create_custom_partitioned_table(name) }
        #
        # Options are:
        #   :primary_key - a array specifying the primary query of the new table
        #   :partition_name_format - the format to be used when naming partitions.
        #     The %{table_name} and %{partition_name} variables are made available.
        #     If not specified, a default is generated
        #   :partition_mappings - a hash specifying the mappings between partition name and respective column value(s)
        #   :create_partitioned_table_fn - a lambda allowing a custom function to create the partitioned table
        #     If not specified, the partitioned table will be created with the same schema as the non-partitioned table
        #
        def partition_table_by_list(
          table_name, column_name,
          primary_key:, partition_mappings: nil, partition_name_format: nil, create_partitioned_table_fn: nil
        )
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          assert_table_is_allowed(table_name)

          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          current_primary_key = Array.wrap(connection.primary_key(table_name))
          raise "primary key not defined for #{table_name}" if current_primary_key.blank?

          partition_column = find_column_definition(table_name, column_name)
          raise "partition column #{column_name} does not exist on #{table_name}" if partition_column.nil?

          primary_key = Array.wrap(primary_key).map(&:to_s)
          raise "the partition column must be part of the primary key" unless primary_key.include?(column_name.to_s)

          primary_key_objects = connection.columns(table_name).select { |column| primary_key.include?(column.name) }

          if partition_mappings.nil?
            distinct_partitions = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
              Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
                define_batchable_model(table_name, connection: connection).distinct(column_name).pluck(column_name)
              end
            end

            partition_mappings = distinct_partitions.to_h { |partition_id| [partition_id, partition_id] }
          end

          raise 'partition_mappings must contain more than one partition' unless partition_mappings.count > 1

          partitioned_table_name = make_partitioned_table_name(table_name)

          with_lock_retries do
            create_list_partitioned_copy(
              table_name, partitioned_table_name, partition_column, primary_key_objects, create_partitioned_table_fn)
            create_list_partitions(partitioned_table_name, partition_mappings, partition_name_format)
            create_trigger_to_sync_tables(table_name, partitioned_table_name, current_primary_key)
          end
        end

        # Clean up a partitioned copy of an existing table. First, deletes the database function and trigger that were
        # used to copy writes to the partitioned table, then removes the partitioned table (also removing partitions).
        #
        # Example:
        #
        #   drop_partitioned_table_for :audit_events
        #
        def drop_partitioned_table_for(table_name)
          assert_table_is_allowed(table_name)
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          with_lock_retries do
            drop_sync_trigger(table_name)
          end

          partitioned_table_name = make_partitioned_table_name(table_name)
          drop_table(partitioned_table_name)
        end

        # Enqueue the background jobs that will backfill data in the partitioned table, by batch-copying records from
        # original table. This helper should be called from a post-deploy migration.
        #
        # Example:
        #
        #   enqueue_partitioning_data_migration :audit_events
        #
        def enqueue_partitioning_data_migration(table_name, migration = MIGRATION)
          assert_table_is_allowed(table_name)

          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          partitioned_table_name = make_partitioned_table_name(table_name)
          primary_key = connection.primary_key(table_name)

          queue_batched_background_migration(
            migration,
            table_name,
            primary_key,
            partitioned_table_name,
            batch_size: BATCH_SIZE,
            sub_batch_size: SUB_BATCH_SIZE,
            job_interval: BATCH_INTERVAL
          )
        end

        # Cleanup a previously enqueued background migration to copy data into a partitioned table. This will not
        # prevent the enqueued jobs from executing, but instead cleans up information in the database used to track the
        # state of the batched background migration. It should be safe to also remove the partitioned table even if the
        # background jobs are still in-progress, as the absence of the table will cause them to safely exit.
        #
        # Example:
        #
        #   cleanup_partitioning_data_migration :audit_events
        #
        def cleanup_partitioning_data_migration(table_name, migration = MIGRATION)
          assert_table_is_allowed(table_name)

          partitioned_table_name = make_partitioned_table_name(table_name)
          primary_key = connection.primary_key(table_name)

          delete_batched_background_migration(migration, table_name, primary_key, [partitioned_table_name])
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

        # Executes jobs from previous BatchedBackgroundMigration to backfill the partitioned table by finishing
        # pending jobs.
        #
        # **NOTE** Migrations using this method cannot be scheduled in the same release as the migration that
        # schedules the background migration using the `enqueue_partitioning_data_migration` helper, or else the
        # background migration jobs will be force-executed.
        #
        # Example:
        #
        #   finalize_backfilling_partitioned_table :audit_events
        #
        def finalize_backfilling_partitioned_table(table_name)
          assert_table_is_allowed(table_name)

          partitioned_table_name = make_partitioned_table_name(table_name)

          unless table_exists?(partitioned_table_name)
            raise "could not find partitioned table for #{table_name}, " \
              "this could indicate the previous partitioning migration has been rolled back."
          end

          ensure_batched_background_migration_is_finished(
            job_class_name: MIGRATION,
            table_name: table_name,
            column_name: connection.primary_key(table_name),
            job_arguments: [partitioned_table_name]
          )

          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
            disable_statement_timeout do
              execute("VACUUM FREEZE ANALYZE #{partitioned_table_name}")
            end
          end
        end

        # Replaces a non-partitioned table with its partitioned copy. This is the final step in a partitioning
        # migration, which makes the partitioned table ready for use by the application. The partitioned copy should be
        # replaced with the original table in such a way that it appears seamless to any database clients. The replaced
        # table will be renamed to "#{replaced_table}_archived". Partitions and primary key constraints will also be
        # renamed to match the naming scheme of the parent table.
        #
        # **NOTE** This method should only be used after all other migration steps have completed successfully.
        # There are several limitations to this method that MUST be handled before, or during, the swap migration:
        #
        # - Secondary indexes and foreign keys are not automatically recreated on the partitioned table.
        # - Some types of constraints (UNIQUE and EXCLUDE) which rely on indexes, will not automatically be recreated
        #   on the partitioned table, since the underlying index will not be present.
        # - Foreign keys referencing the original non-partitioned table, would also need to be updated to reference the
        #   partitioned table, but unfortunately this is not supported in PG11.
        # - Views referencing the original table will not be automatically updated to reference the partitioned table.
        #
        # Example:
        #
        #   replace_with_partitioned_table :audit_events
        #
        def replace_with_partitioned_table(table_name)
          assert_table_is_allowed(table_name)

          partitioned_table_name = make_partitioned_table_name(table_name)
          archived_table_name = make_archived_table_name(table_name)
          primary_key_name = connection.primary_key(table_name)

          replace_table(table_name, partitioned_table_name, archived_table_name, primary_key_name)
        end

        # Rolls back a migration that replaced a non-partitioned table with its partitioned copy. This can be used to
        # restore the original non-partitioned table in the event of an unexpected issue.
        #
        # Example:
        #
        #   rollback_replace_with_partitioned_table :audit_events
        #
        def rollback_replace_with_partitioned_table(table_name)
          assert_table_is_allowed(table_name)

          partitioned_table_name = make_partitioned_table_name(table_name)
          archived_table_name = make_archived_table_name(table_name)
          primary_key_name = connection.primary_key(archived_table_name)

          replace_table(table_name, archived_table_name, partitioned_table_name, primary_key_name)
        end

        def drop_nonpartitioned_archive_table(table_name)
          assert_table_is_allowed(table_name)

          archived_table_name = make_archived_table_name(table_name)

          with_lock_retries do
            drop_sync_trigger(table_name)
          end

          drop_table(archived_table_name)
        end

        def create_trigger_to_sync_tables(source_table_name, partitioned_table_name, unique_key)
          function_name = make_sync_function_name(source_table_name)
          trigger_name = make_sync_trigger_name(source_table_name)

          create_sync_function(function_name, source_table_name, partitioned_table_name, unique_key)
          create_comment('FUNCTION', function_name, "Partitioning migration: table sync for #{source_table_name} table")

          create_sync_trigger(source_table_name, trigger_name, function_name)
        end

        def prepare_constraint_for_list_partitioning(table_name:, partitioning_column:, parent_table_name:, initial_partitioning_value:, async: false)
          validate_not_in_transaction!(:prepare_constraint_for_list_partitioning)

          Gitlab::Database::Partitioning::List::ConvertTable
            .new(migration_context: self,
              table_name: table_name,
              parent_table_name: parent_table_name,
              partitioning_column: partitioning_column,
              zero_partition_value: initial_partitioning_value
            ).prepare_for_partitioning(async: async)
        end

        def revert_preparing_constraint_for_list_partitioning(table_name:, partitioning_column:, parent_table_name:, initial_partitioning_value:)
          validate_not_in_transaction!(:revert_preparing_constraint_for_list_partitioning)

          Gitlab::Database::Partitioning::List::ConvertTable
            .new(migration_context: self,
              table_name: table_name,
              parent_table_name: parent_table_name,
              partitioning_column: partitioning_column,
              zero_partition_value: initial_partitioning_value
            ).revert_preparation_for_partitioning
        end

        def convert_table_to_first_list_partition(table_name:, partitioning_column:, parent_table_name:, initial_partitioning_value:, lock_tables: [])
          validate_not_in_transaction!(:convert_table_to_first_list_partition)

          Gitlab::Database::Partitioning::List::ConvertTable
            .new(migration_context: self,
              table_name: table_name,
              parent_table_name: parent_table_name,
              partitioning_column: partitioning_column,
              zero_partition_value: initial_partitioning_value
            ).partition
        end

        def revert_converting_table_to_first_list_partition(table_name:, partitioning_column:, parent_table_name:, initial_partitioning_value:)
          validate_not_in_transaction!(:revert_converting_table_to_first_list_partition)

          Gitlab::Database::Partitioning::List::ConvertTable
            .new(migration_context: self,
              table_name: table_name,
              parent_table_name: parent_table_name,
              partitioning_column: partitioning_column,
              zero_partition_value: initial_partitioning_value
            ).revert_partitioning
        end

        private

        def assert_table_is_allowed(table_name)
          return if ALLOWED_TABLES.include?(table_name.to_s)

          raise "partitioning helpers are in active development, and #{table_name} is not allowed for use, " \
            "for more information please contact the database team"
        end

        def make_partitioned_table_name(table)
          tmp_table_name(table)
        end

        def make_archived_table_name(table)
          "#{table}_archived"
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

        def create_partitioned_copy(
          source_table_name, partitioning_type, partitioned_table_name, partition_column, primary_keys,
          create_partitioned_table_fn = nil
        )

          if table_exists?(partitioned_table_name)
            Gitlab::AppLogger.warn "Partitioned table not created because it already exists " \
              "(this may be due to an aborted migration or similar): table_name: #{partitioned_table_name} "
            return
          end

          return create_partitioned_table_fn.call(partitioned_table_name) if create_partitioned_table_fn.is_a?(Proc)

          tmp_partitioning_column_name = "#{partition_column.name}_tmp"

          temporary_columns = primary_keys.map { |key| "#{key.name}_tmp" }.join(", ")
          temporary_columns_statement = build_temporary_columns_statement(primary_keys)

          transaction do
            execute(<<~SQL)
              CREATE TABLE #{partitioned_table_name} (
                LIKE #{source_table_name} INCLUDING ALL EXCLUDING INDEXES,
                 #{temporary_columns_statement},
                PRIMARY KEY (#{temporary_columns})
              ) PARTITION #{partitioning_type} (#{tmp_partitioning_column_name})
            SQL

            primary_keys.each do |key|
              remove_column(partitioned_table_name, key.name)
              rename_column(partitioned_table_name, "#{key.name}_tmp", key.name)
            end
          end
        end

        def create_list_partitioned_copy(
          source_table_name, partitioned_table_name, partition_column, primary_keys, create_partitioned_table_fn = nil
        )
          create_partitioned_copy(
            source_table_name, 'BY LIST', partitioned_table_name, partition_column, primary_keys,
            create_partitioned_table_fn
          )
        end

        def create_range_id_partitioned_copy(source_table_name, partitioned_table_name, partition_column, primary_keys)
          create_partitioned_copy(source_table_name, 'BY RANGE', partitioned_table_name, partition_column, primary_keys)
        end

        def create_range_partitioned_copy(source_table_name, partitioned_table_name, partition_column, primary_key)
          if table_exists?(partitioned_table_name)
            Gitlab::AppLogger.warn "Partitioned table not created because it already exists " \
              "(this may be due to an aborted migration or similar): table_name: #{partitioned_table_name} "
            return
          end

          tmp_column_name = object_name(partition_column.name, 'partition_key')
          transaction do
            execute(<<~SQL)
              CREATE TABLE #{partitioned_table_name} (
                LIKE #{source_table_name} INCLUDING ALL EXCLUDING INDEXES,
                #{tmp_column_name} #{partition_column.sql_type} NOT NULL,
                PRIMARY KEY (#{[primary_key, tmp_column_name].join(', ')})
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

        def create_list_partitions(table_name, partition_mappings, partition_name_format = nil)
          partition_name_format ||= "%{table_name}_%{partition_name}"

          partition_mappings.each_pair do |partition_name, partition_values|
            partition_name = format(partition_name_format, table_name: table_name, partition_name: partition_name)
            create_list_partition_safely(partition_name, table_name, partition_values)
          end
        end

        def create_int_range_partitions(table_name, partition_size, min_id, max_id)
          lower_bound = min_id
          upper_bound = min_id + partition_size

          end_id = max_id + (PARTITION_BUFFER * partition_size) # Adds a buffer of 6 partitions

          while lower_bound < end_id
            create_range_partition_safely("#{table_name}_#{lower_bound}", table_name, lower_bound, upper_bound)

            lower_bound += partition_size
            upper_bound += partition_size
          end
        end

        def to_sql_date_literal(date)
          connection.quote(date.iso8601)
        end

        def create_range_partition_safely(partition_name, table_name, lower_bound, upper_bound)
          if table_exists?(table_for_range_partition(partition_name))
            Gitlab::AppLogger.warn "Partition not created because it already exists " \
              "(this may be due to an aborted migration or similar): partition_name: #{partition_name}"
            return
          end

          create_range_partition(partition_name, table_name, lower_bound, upper_bound)
        end

        def create_list_partition_safely(partition_name, table_name, partition_values)
          if table_exists?(table_for_list_partition(partition_name))
            Gitlab::AppLogger.warn "Partition not created because it already exists " \
              "(this may be due to an aborted migration or similar): partition_name: #{partition_name}"
            return
          end

          create_list_partition(partition_name, table_name, partition_values)
        end

        def drop_sync_trigger(source_table_name)
          trigger_name = make_sync_trigger_name(source_table_name)
          drop_trigger(source_table_name, trigger_name)

          function_name = make_sync_function_name(source_table_name)
          drop_function(function_name)
        end

        def create_sync_function(name, source_table_name, partitioned_table_name, unique_key)
          if function_exists?(name)
            Gitlab::AppLogger.warn "Partitioning sync function not created because it already exists " \
              "(this may be due to an aborted migration or similar): function name: #{name}"
            return
          end

          unique_key = Array.wrap(unique_key).map(&:to_s)

          delimiter = ",\n    "
          column_names = connection.columns(partitioned_table_name).map(&:name)
          set_statements = build_set_statements(column_names, unique_key)
          insert_values = column_names.map { |name| "NEW.#{connection.quote_column_name(name)}" }
          delete_where_statement = unique_key.map { |unique_key| "#{connection.quote_column_name(unique_key)} = OLD.#{connection.quote_column_name(unique_key)}" }.join(' AND ')
          update_where_statement = unique_key.map { |unique_key| "#{partitioned_table_name}.#{connection.quote_column_name(unique_key)} = NEW.#{connection.quote_column_name(unique_key)}" }.join(' AND ')

          create_trigger_function(name, replace: false) do
            <<~SQL
              IF (TG_OP = 'DELETE') THEN
                DELETE FROM #{partitioned_table_name} where #{delete_where_statement};
              ELSIF (TG_OP = 'UPDATE') THEN
                UPDATE #{partitioned_table_name}
                SET #{set_statements.join(delimiter)}
                WHERE #{update_where_statement};
              ELSIF (TG_OP = 'INSERT') THEN
                INSERT INTO #{partitioned_table_name} (#{column_names.map { |name| connection.quote_column_name(name).to_s }.join(delimiter)})
                VALUES (#{insert_values.join(delimiter)});
              END IF;
              RETURN NULL;
            SQL
          end
        end

        def build_temporary_columns_statement(columns)
          columns.map do |column|
            type = column.name == 'id' || column.name.end_with?('_id') ? 'bigint' : column.sql_type

            "#{column.name}_tmp #{type} NOT NULL"
          end.join(", ")
        end

        def build_set_statements(column_names, unique_key)
          column_names.reject { |name| unique_key.include?(name) }
            .map { |name| "#{connection.quote_column_name(name)} = NEW.#{connection.quote_column_name(name)}" }
        end

        def create_sync_trigger(table_name, trigger_name, function_name)
          if trigger_exists?(table_name, trigger_name)
            Gitlab::AppLogger.warn "Partitioning sync trigger not created because it already exists " \
              "(this may be due to an aborted migration or similar): trigger name: #{trigger_name}"
            return
          end

          create_trigger(table_name, trigger_name, function_name, fires: 'AFTER INSERT OR UPDATE OR DELETE')
        end

        def replace_table(original_table_name, replacement_table_name, replaced_table_name, primary_key_name)
          replace_table = Gitlab::Database::Partitioning::ReplaceTable.new(connection,
            original_table_name.to_s, replacement_table_name, replaced_table_name, primary_key_name)

          transaction do
            drop_sync_trigger(original_table_name)

            replace_table.perform do |sql|
              say("replace_table(\"#{sql}\")")
            end

            create_trigger_to_sync_tables(original_table_name, replaced_table_name, primary_key_name)
          end
        end
      end
    end
  end
end
