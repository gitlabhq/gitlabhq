# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module Conversions
        class BigintConverter
          include Gitlab::Utils::StrongMemoize

          MIN_MILESTONE = '17.4'
          DEFAULT_VALUE_MAP = {
            integer: 0,
            bigint: 0,
            uuid: '00000000-0000-0000-0000-000000000000'
          }.freeze

          YAML_FILE_PATH = 'db/integer_ids_not_yet_initialized_to_bigint.yml'
          YAML_HEADER = <<~MESSAGE
            # -- DON'T MANUALLY EDIT --
            # Contains the list of integer IDs which were converted to bigint for new installations in
            # https://gitlab.com/gitlab-org/gitlab/-/issues/438124, but they are still integers for existing instances.
            # On initialize_conversion_of_integer_to_bigint those integer IDs will be removed automatically from here.
          MESSAGE

          def initialize(migration, table, columns)
            @migration = migration
            @table = table.to_s
            @columns = Array.wrap(columns).map(&:to_s)
          end

          def init
            verify_table_and_columns_exist!
            return if all_converted?

            verify_all_integer_ids_are_included!
            check_trigger_permissions!
            # The reason why `disable_ddl_transaction!` is required
            # for `initialize_conversion_of_integer_to_bigint`
            migration.with_lock_retries do
              # Only integer columns should be considered
              # because in new instance, every ID will be bigint and should be skipped for conversion
              create_bigint_columns(source: integer_columns, type: 'bigint')
              create_trigger
            end
          end

          def revert_init
            verify_table_and_columns_exist!
            check_trigger_permissions!
            # Same as what `initialize_conversion_of_integer_to_bigint` does
            migration.with_lock_retries do
              remove_bigint_columns
              remove_trigger
            end
          end

          def restore_cleanup
            verify_table_and_columns_exist!
            check_trigger_permissions!
            # All given columns should be bigint for now
            # If source is integer_columns, there will be no columns to restore
            create_bigint_columns(source: selected_columns, type: 'integer')
            create_trigger
          end

          def cleanup
            revert_init
            update_file_for_integer_ids_not_yet_initialized_to_bigint
          end

          # We will queue the job and let the job to check if columns exist and continue with the copy
          def backfill(primary_key:, batch_size:, sub_batch_size:, pause_ms:, job_interval:)
            verify_table_and_columns_exist!
            migration.queue_batched_background_migration(
              'CopyColumnUsingBackgroundMigrationJob',
              table,
              primary_key,
              *column_pair,
              job_interval: job_interval,
              pause_ms: pause_ms,
              batch_size: batch_size,
              sub_batch_size: sub_batch_size
            )
          end

          def ensure_backfill(primary_key:)
            verify_table_and_columns_exist!
            migration.ensure_batched_background_migration_is_finished(
              job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
              table_name: table,
              column_name: primary_key,
              job_arguments: column_pair
            )
          end

          def revert_backfill(primary_key:)
            verify_table_and_columns_exist!
            migration.delete_batched_background_migration(
              'CopyColumnUsingBackgroundMigrationJob',
              table,
              primary_key,
              column_pair
            )
          end

          private

          attr_reader :migration, :table, :columns

          def verify_table_and_columns_exist!
            raise "Table #{table} does not exist" unless migration.table_exists?(table)

            unknown_column_names = columns - all_columns.map(&:name)
            return if unknown_column_names.blank?

            raise "Columns #{unknown_column_names.join(', ')} does not exist on #{table}"
          end

          def all_converted?
            integer_columns.blank?.tap do
              Gitlab::AppLogger.warn(
                message: 'The columns are already of type bigint.',
                table: table, columns: columns
              )
            end
          end

          def verify_all_integer_ids_are_included!
            return if initialization_for_all_integer_ids_not_required?

            missing_integer_ids = all_table_integer_ids.fetch(table, []) - columns
            return if missing_integer_ids.blank?

            raise <<~ERROR
              Table #{table} still has integer ID columns (#{missing_integer_ids.join(', ')}).
              Please include them in the 'columns' param and in your backfill migration.
              For more info: https://gitlab.com/gitlab-org/gitlab/-/issues/482470
            ERROR
          end

          # This check can be removed once we convert all integer IDs to bigint
          # in https://gitlab.com/gitlab-org/gitlab/-/issues/465805
          def initialization_for_all_integer_ids_not_required?
            !migration.respond_to?(:milestone) ||
              Gitlab::VersionInfo.parse_from_milestone(migration.milestone) <
                Gitlab::VersionInfo.parse_from_milestone(MIN_MILESTONE)
          end

          def all_table_integer_ids
            YAML.safe_load_file(File.join(YAML_FILE_PATH))
          rescue Errno::ENOENT
            {}
          end
          strong_memoize_attr :all_table_integer_ids

          def check_trigger_permissions!
            migration.check_trigger_permissions!(table)
          end

          def create_bigint_columns(source:, type:)
            bigint_columns_for_conversion(source: source).each do |options|
              migration.add_column(
                table, options[:name], type,
                if_not_exists: true, **options.except(:name)
              )
            end

            clear_memoization(:all_columns)
          end

          def remove_bigint_columns
            # We don't need to worry about the `columns` are type integer or bigint
            # For reverting the initialization, the `columns` are type integer
            # For cleaning up the conversion, the `columns` will be type bigint
            # We just need to remove the columns with `_convert_to_bigint` suffix
            bigint_columns_for_conversion(source: selected_columns).each do |options|
              migration.remove_column(table, options[:name], if_exists: true)
            end

            clear_memoization(:all_columns)
          end

          # Since trigger checks if bigint column for conversion exists or not,
          # the full list of columns can be used to ensure same trigger name can be used
          # across all different instances.
          def create_trigger
            migration.install_rename_triggers(table, *column_pair)
          end

          def remove_trigger
            trigger_name = migration.rename_trigger_name(table, *column_pair)
            migration.remove_rename_triggers(table, trigger_name)
          end

          def all_columns
            migration.columns(table)
          end
          strong_memoize_attr :all_columns

          def selected_columns
            all_columns.select { |column| columns.include?(column.name) }
          end

          def integer_columns
            selected_columns.select { |column| column.sql_type == 'integer' }
          end

          def bigint_columns_for_conversion(source:)
            source.map do |column|
              {
                name: migration.convert_to_bigint_column(column.name),
                default: default_for(column),
                null: nullable?(column),
                array: column.array
              }
            end
          end

          def all_bigint_column_names
            all_columns.filter_map { |column| column.name if column.sql_type == 'bigint' }
          end

          def column_pair
            [
              columns,
              columns.map { |name| migration.convert_to_bigint_column(name) }
            ]
          end

          def default_for(column)
            return column.default if nullable?(column)

            # If the column to be converted is either a PK or is defined as NOT NULL,
            # set it to `NOT NULL DEFAULT 0` and we'll copy paste the correct values bellow
            # That way, we skip the expensive validation step required to add
            # a NOT NULL constraint at the end of the process
            column.default || DEFAULT_VALUE_MAP.fetch(column.sql_type.to_sym)
          end

          def nullable?(column)
            !primary_key?(column) && column.null
          end

          def primary_key?(column)
            primary_keys.include?(column.name)
          end

          def primary_keys
            Array.wrap(
              # For single primary key, it's a string, e.g. `'id'`
              # For composite primary key, it's an array, e.g. `['id', 'partition_id']`
              migration.primary_key(table)
            )
          end
          strong_memoize_attr :primary_keys

          def update_file_for_integer_ids_not_yet_initialized_to_bigint
            return unless Rails.env.development? || Rails.env.test?
            return if initialization_for_all_integer_ids_not_required?

            remaining_integer_ids = all_table_integer_ids.fetch(table, []) - all_bigint_column_names
            new_table_integer_ids =
              if remaining_integer_ids.blank?
                all_table_integer_ids.except(table)
              else
                all_table_integer_ids.merge(table => remaining_integer_ids)
              end

            if new_table_integer_ids.blank?
              FileUtils.rm_f(YAML_FILE_PATH)
            else
              File.open(YAML_FILE_PATH, 'w') do |file|
                file.write(YAML_HEADER)
                file.write(new_table_integer_ids.stringify_keys.to_yaml)
              end
            end
          end
        end
      end
    end
  end
end
