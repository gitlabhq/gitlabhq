# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      include Migrations::ReestablishedConnectionStack
      include Migrations::BackgroundMigrationHelpers
      include Migrations::BatchedBackgroundMigrationHelpers
      include Migrations::LockRetriesHelpers
      include Migrations::TimeoutHelpers
      include Migrations::ConstraintsHelpers
      include Migrations::ExtensionHelpers
      include Migrations::SidekiqHelpers
      include Migrations::RedisHelpers
      include DynamicModelHelpers
      include RenameTableHelpers
      include AsyncIndexes::MigrationHelpers
      include AsyncConstraints::MigrationHelpers
      include WraparoundVacuumHelpers
      include PartitionHelpers

      INTEGER_IDS_YET_TO_INITIALIZED_TO_BIGINT_FILE_PATH = 'db/integer_ids_not_yet_initialized_to_bigint.yml'

      TABLE_INT_IDS_YAML_FILE_COMMENT = <<-MESSAGE.strip_heredoc
        # -- DON'T MANUALLY EDIT --
        # Contains the list of integer IDs which were converted to bigint for new installations in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/438124, but they are still integers for existing instances.
        # On initialize_conversion_of_integer_to_bigint those integer IDs will be removed automatically from here.
      MESSAGE

      PENDING_INT_IDS_ERROR_MSG = "'%{table}' table still has %{int_ids} integer IDs. "\
        "Please include them in the 'columns' param and in your backfill migration. "\
        "For more info: https://gitlab.com/gitlab-org/gitlab/-/issues/482470"

      ENFORCE_INITIALIZE_ALL_INT_IDS_FROM_MILESTONE = '17.4'

      DEFAULT_TIMESTAMP_COLUMNS = %i[created_at updated_at].freeze

      def define_batchable_model(
        table_name,
        connection: self.connection,
        primary_key: nil,
        base_class: ActiveRecord::Base
      )
        super
      end

      def each_batch(table_name, connection: self.connection, **kwargs)
        super(table_name, connection: connection, **kwargs)
      end

      def each_batch_range(table_name, connection: self.connection, **kwargs)
        super(table_name, connection: connection, **kwargs)
      end

      # Adds `created_at` and `updated_at` columns with timezone information.
      #
      # This method is an improved version of Rails' built-in method `add_timestamps`.
      #
      # By default, adds `created_at` and `updated_at` columns, but these can be specified as:
      #
      #   add_timestamps_with_timezone(:my_table, columns: [:created_at, :deleted_at])
      #
      # This allows you to create just the timestamps you need, saving space.
      #
      # Available options are:
      #  :default - The default value for the column.
      #  :null - When set to `true` the column will allow NULL values.
      #        The default is to not allow NULL values.
      #  :columns - the column names to create. Must end with `_at`.
      #             Default value: `DEFAULT_TIMESTAMP_COLUMNS`
      #
      # All options are optional.
      def add_timestamps_with_timezone(table_name, options = {})
        columns = options.fetch(:columns, DEFAULT_TIMESTAMP_COLUMNS)

        columns.each do |column_name|
          validate_timestamp_column_name!(column_name)

          add_column(
            table_name,
            column_name,
            :datetime_with_timezone,
            default: options[:default],
            null: options[:null] || false
          )
        end
      end

      # To be used in the `#down` method of migrations that
      # use `#add_timestamps_with_timezone`.
      #
      # Available options are:
      #  :columns - the column names to remove. Must be one
      #             Default value: `DEFAULT_TIMESTAMP_COLUMNS`
      #
      # All options are optional.
      def remove_timestamps(table_name, options = {})
        columns = options.fetch(:columns, DEFAULT_TIMESTAMP_COLUMNS)
        columns.each do |column_name|
          remove_column(table_name, column_name)
        end
      end

      # Creates a new index, concurrently
      #
      # Example:
      #
      #     add_concurrent_index :users, :some_column
      #
      # See Rails' `add_index` for more info on the available arguments.
      def add_concurrent_index(table_name, column_name, options = {})
        if transaction_open?
          raise 'add_concurrent_index can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        if !options.delete(:allow_partition) && partition?(table_name)
          raise ArgumentError, 'add_concurrent_index can not be used on a partitioned '  \
            'table. Please use add_concurrent_partitioned_index on the partitioned table ' \
            'as we need to create indexes on each partition and an index on the parent table'
        end

        options = options.merge({ algorithm: :concurrently })

        if index_exists?(table_name, column_name, **options)
          name = options[:name] || index_name(table_name, column_name)
          _, schema = table_name.to_s.split('.').reverse

          if index_invalid?(name, schema: schema)
            say "Index being recreated because the existing version was INVALID: table_name: #{table_name}, column_name: #{column_name}"

            remove_concurrent_index_by_name(table_name, name)
          else
            say "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"

            return
          end
        end

        disable_statement_timeout do
          add_index(table_name, column_name, **options)
        end

        # We created this index. Now let's remove the queuing entry for async creation in case it's still there.
        unprepare_async_index(table_name, column_name, **options)
      end

      def index_invalid?(index_name, schema: nil)
        index_name = connection.quote(index_name)
        schema = connection.quote(schema) if schema
        schema ||= 'current_schema()'

        connection.select_value(<<~SQL)
          select not i.indisvalid
          from pg_class c
          inner join pg_index i
            on c.oid = i.indexrelid
          inner join pg_namespace n
            on n.oid = c.relnamespace
          where n.nspname = #{schema}
            and c.relname = #{index_name}
        SQL
      end

      # Removes an existed index, concurrently
      #
      # Example:
      #
      #     remove_concurrent_index :users, :some_column
      #
      # See Rails' `remove_index` for more info on the available arguments.
      def remove_concurrent_index(table_name, column_name, options = {})
        if transaction_open?
          raise 'remove_concurrent_index can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        if partition?(table_name)
          raise ArgumentError, 'remove_concurrent_index can not be used on a partitioned '  \
            'table. Please use remove_concurrent_partitioned_index_by_name on the partitioned table ' \
            'as we need to remove the index on the parent table'
        end

        options = options.merge({ algorithm: :concurrently })

        unless index_exists?(table_name, column_name, **options)
          Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
          return
        end

        disable_statement_timeout do
          remove_index(table_name, **options.merge({ column: column_name }))
        end

        # We removed this index. Now let's make sure it's not queued for async creation.
        unprepare_async_index(table_name, column_name, **options)
      end

      # Removes an existing index, concurrently
      #
      # Example:
      #
      #     remove_concurrent_index :users, "index_X_by_Y"
      #
      # See Rails' `remove_index` for more info on the available arguments.
      def remove_concurrent_index_by_name(table_name, index_name, options = {})
        if transaction_open?
          raise 'remove_concurrent_index_by_name can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        if partition?(table_name)
          raise ArgumentError, 'remove_concurrent_index_by_name can not be used on a partitioned '  \
            'table. Please use remove_concurrent_partitioned_index_by_name on the partitioned table ' \
            'as we need to remove the index on the parent table'
        end

        index_name = index_name[:name] if index_name.is_a?(Hash)

        raise 'remove_concurrent_index_by_name must get an index name as the second argument' if index_name.blank?

        options = options.merge({ algorithm: :concurrently })

        unless index_exists_by_name?(table_name, index_name)
          Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, index_name: #{index_name}"
          return
        end

        disable_statement_timeout do
          remove_index(table_name, **options.merge({ name: index_name }))
        end

        # We removed this index. Now let's make sure it's not queued for async creation.
        unprepare_async_index_by_name(table_name, index_name, **options)
      end

      # Adds a foreign key with only minimal locking on the tables involved.
      #
      # This method only requires minimal locking
      #
      # source - The source table containing the foreign key.
      # target - The target table the key points to.
      # column - The name of the column to create the foreign key on.
      # target_column - The name of the referenced column, defaults to "id".
      # on_delete - The action to perform when associated data is removed,
      #             defaults to "CASCADE".
      # on_update - The action to perform when associated data is updated,
      #             defaults to nil. This is useful for multi column FKs if
      #             it's desirable to update one of the columns.
      # name - The name of the foreign key.
      # validate - Flag that controls whether the new foreign key will be validated after creation.
      #            If the flag is not set, the constraint will only be enforced for new data.
      # reverse_lock_order - Flag that controls whether we should attempt to acquire locks in the reverse
      #                      order of the ALTER TABLE. This can be useful in situations where the foreign
      #                      key creation could deadlock with another process.
      #
      def add_concurrent_foreign_key(source, target, column:, **options)
        options.reverse_merge!({
          on_delete: :cascade,
          on_update: nil,
          target_column: :id,
          validate: true,
          reverse_lock_order: false,
          allow_partitioned: false,
          column: column
        })

        # Transactions would result in ALTER TABLE locks being held for the
        # duration of the transaction, defeating the purpose of this method.
        if transaction_open?
          raise 'add_concurrent_foreign_key can not be run inside a transaction'
        end

        if !options.delete(:allow_partitioned) && table_partitioned?(source)
          raise ArgumentError, 'add_concurrent_foreign_key can not be used on a partitioned ' \
            'table. Please use add_concurrent_partitioned_foreign_key on the partitioned table ' \
            'as we need to create foreign keys on each partition and a FK on the parent table'
        end

        options[:name] ||= concurrent_foreign_key_name(source, column)
        options[:primary_key] = options[:target_column]
        check_options = options.slice(:column, :on_delete, :on_update, :name, :primary_key)

        if foreign_key_exists?(source, target, **check_options)
          warning_message = "Foreign key not created because it exists already " \
            "(this may be due to an aborted migration or similar): " \
            "source: #{source}, target: #{target}, column: #{options[:column]}, "\
            "name: #{options[:name]}, on_update: #{options[:on_update]}, "\
            "on_delete: #{options[:on_delete]}"

          Gitlab::AppLogger.warn warning_message
        else
          execute_add_concurrent_foreign_key(source, target, options)
        end

        # Validate the existing constraint. This can potentially take a very
        # long time to complete, but fortunately does not lock the source table
        # while running.
        # Disable this check by passing `validate: false` to the method call
        # The check will be enforced for new data (inserts) coming in,
        # but validating existing data is delayed.
        #
        # Note this is a no-op in case the constraint is VALID already

        if options[:validate]
          begin
            disable_statement_timeout do
              execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{options[:name]};")
            end
          rescue PG::ForeignKeyViolation => e
            with_lock_retries do
              execute("ALTER TABLE #{source} DROP CONSTRAINT #{options[:name]};")
            end
            raise "Migration failed intentionally due to ForeignKeyViolation: #{e.message}"
          end
        end
      end

      def validate_foreign_key(source, column, name: nil)
        fk_name = name || concurrent_foreign_key_name(source, column)

        unless foreign_key_exists?(source, name: fk_name)
          raise missing_schema_object_message(source, "foreign key", fk_name)
        end

        disable_statement_timeout do
          execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{fk_name};")
        end
      end

      def foreign_key_exists?(source, target = nil, **options)
        # This if block is necessary because foreign_key_exists? is called in down migrations that may execute before
        # the postgres_foreign_keys view had necessary columns added.
        # In that case, we revert to the previous behavior of this method.
        # The behavior in the if block has a bug: it always returns false if the fk being checked has multiple columns.
        # This can be removed after init_schema.rb passes 20221122210711_add_columns_to_postgres_foreign_keys.rb
        # Tracking issue: https://gitlab.com/gitlab-org/gitlab/-/issues/386796
        unless connection.column_exists?('postgres_foreign_keys', 'constrained_table_name')
          return foreign_keys(source).any? do |foreign_key|
            tables_match?(target.to_s, foreign_key.to_table.to_s) &&
                options_match?(foreign_key.options, options)
          end
        end

        # Since we may be migrating in one go from a previous version without
        # `constrained_table_name` then we may see that this column exists
        # (as above) but the schema cache is still outdated for the model.
        unless Gitlab::Database::PostgresForeignKey.column_names.include?('constrained_table_name')
          Gitlab::Database::PostgresForeignKey.reset_column_information
        end

        fks = Gitlab::Database::PostgresForeignKey.by_constrained_table_name_or_identifier(source)

        fks = fks.by_referenced_table_name(target) if target
        fks = fks.by_name(options[:name]) if options[:name]
        fks = fks.by_constrained_columns(options[:column]) if options[:column]
        fks = fks.by_referenced_columns(options[:primary_key]) if options[:primary_key]
        fks = fks.by_on_delete_action(options[:on_delete]) if options[:on_delete]

        fks.exists?
      end

      # Returns the name for a concurrent foreign key.
      #
      # PostgreSQL constraint names have a limit of 63 bytes. The logic used
      # here is based on Rails' foreign_key_name() method, which unfortunately
      # is private so we can't rely on it directly.
      #
      # prefix:
      # - The default prefix is `fk_` for backward compatibility with the existing
      # concurrent foreign key helpers.
      # - For standard rails foreign keys the prefix is `fk_rails_`
      #
      def concurrent_foreign_key_name(table, column, prefix: 'fk_')
        identifier = "#{table}_#{multiple_columns(column, separator: '_')}_fk"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

        "#{prefix}#{hashed_identifier}"
      end

      def true_value
        Database.true_value
      end

      def false_value
        Database.false_value
      end

      # Updates the value of a column in batches.
      #
      # This method updates the table in batches of 5% of the total row count.
      # A `batch_size` option can also be passed to set this to a fixed number.
      # This method will continue updating rows until no rows remain.
      #
      # When given a block this method will yield two values to the block:
      #
      # 1. An instance of `Arel::Table` for the table that is being updated.
      # 2. The query to run as an Arel object.
      #
      # By supplying a block one can add extra conditions to the queries being
      # executed. Note that the same block is used for _all_ queries.
      #
      # Example:
      #
      #     update_column_in_batches(:projects, :foo, 10) do |table, query|
      #       query.where(table[:some_column].eq('hello'))
      #     end
      #
      # This would result in this method updating only rows where
      # `projects.some_column` equals "hello".
      #
      # table - The name of the table.
      # column - The name of the column to update.
      # value - The value for the column.
      #
      # The `value` argument is typically a literal. To perform a computed
      # update, an Arel literal can be used instead:
      #
      #     update_value = Arel.sql('bar * baz')
      #
      #     update_column_in_batches(:projects, :foo, update_value) do |table, query|
      #       query.where(table[:some_column].eq('hello'))
      #     end
      #
      # Rubocop's Metrics/AbcSize metric is disabled for this method as Rubocop
      # determines this method to be too complex while there's no way to make it
      # less "complex" without introducing extra methods (which actually will
      # make things _more_ complex).
      #
      # `batch_column_name` option is for tables without primary key, in this
      # case another unique integer column can be used. Example: :user_id
      #
      # rubocop: disable Metrics/AbcSize
      def update_column_in_batches(table_name, column, value, batch_size: nil, batch_column_name: :id, disable_lock_writes: false)
        if transaction_open?
          raise 'update_column_in_batches can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        table = Arel::Table.new(table_name)

        count_arel = table.project(Arel.star.count.as('count'))
        count_arel = yield table, count_arel if block_given?

        total = exec_query(count_arel.to_sql).to_a.first['count'].to_i

        return if total == 0

        if batch_size.nil?
          # Update in batches of 5% until we run out of any rows to update.
          batch_size = ((total / 100.0) * 5.0).ceil
          max_size = 1000

          # The upper limit is 1000 to ensure we don't lock too many rows. For
          # example, for "merge_requests" even 1% of the table is around 35 000
          # rows for GitLab.com.
          batch_size = max_size if batch_size > max_size
        end

        start_arel = table.project(table[batch_column_name]).order(table[batch_column_name].asc).take(1)
        start_arel = yield table, start_arel if block_given?
        start_id = exec_query(start_arel.to_sql).to_a.first[batch_column_name.to_s].to_i

        loop do
          stop_arel = table.project(table[batch_column_name])
            .where(table[batch_column_name].gteq(start_id))
            .order(table[batch_column_name].asc)
            .take(1)
            .skip(batch_size)

          stop_arel = yield table, stop_arel if block_given?
          stop_row = exec_query(stop_arel.to_sql).to_a.first

          update_arel = Arel::UpdateManager.new
            .table(table)
            .set([[table[column], value]])
            .where(table[batch_column_name].gteq(start_id))

          if stop_row
            stop_id = stop_row[batch_column_name.to_s].to_i
            start_id = stop_id
            update_arel = update_arel.where(table[batch_column_name].lt(stop_id))
          end

          update_arel = yield table, update_arel if block_given?

          transaction do
            execute("SELECT set_config('lock_writes.#{table_name}', 'false', true)") if disable_lock_writes
            execute(update_arel.to_sql)
          end

          # There are no more rows left to update.
          break unless stop_row
        end
      end

      # Renames a column without requiring downtime.
      #
      # Concurrent renames work by using database triggers to ensure both the
      # old and new column are in sync. However, this method will _not_ remove
      # the triggers or the old column automatically; this needs to be done
      # manually in a post-deployment migration. This can be done using the
      # method `cleanup_concurrent_column_rename`.
      #
      # table - The name of the database table containing the column.
      # old - The old column name.
      # new - The new column name.
      # type - The type of the new column. If no type is given the old column's
      #        type is used.
      # batch_column_name - option is for tables without primary key, in this
      #        case another unique integer column can be used. Example: :user_id
      def rename_column_concurrently(table, old, new, type: nil, type_cast_function: nil, batch_column_name: :id)
        unless column_exists?(table, batch_column_name)
          raise "Column #{batch_column_name} does not exist on #{table}"
        end

        if transaction_open?
          raise 'rename_column_concurrently can not be run inside a transaction'
        end

        check_trigger_permissions!(table)

        create_column_from(table, old, new, type: type, batch_column_name: batch_column_name, type_cast_function: type_cast_function)

        install_rename_triggers(table, old, new)
      end

      # Reverses operations performed by rename_column_concurrently.
      #
      # This method takes care of removing previously installed triggers as well
      # as removing the new column.
      #
      # table - The name of the database table.
      # old - The name of the old column.
      # new - The name of the new column.
      def undo_rename_column_concurrently(table, old, new)
        trigger_name = rename_trigger_name(table, old, new)

        check_trigger_permissions!(table)

        remove_rename_triggers(table, trigger_name)

        remove_column(table, new)
      end

      # Installs triggers in a table that keep a new column in sync with an old
      # one.
      #
      # table - The name of the table to install the trigger in.
      # old_column - The name of the old column.
      # new_column - The name of the new column.
      # trigger_name - The name of the trigger to use (optional).
      def install_rename_triggers(table, old, new, trigger_name: nil)
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).create(old, new, trigger_name: trigger_name)
      end

      # Removes the triggers used for renaming a column concurrently.
      def remove_rename_triggers(table, trigger)
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).drop(trigger)
      end

      # Returns the (base) name to use for triggers when renaming columns.
      def rename_trigger_name(table, old, new)
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table, connection: connection).name(old, new)
      end

      # Installs a trigger in a table that assigns a sharding key from an associated table.
      #
      # table: The table to install the trigger in.
      # sharding_key: The column to be assigned on `table`.
      # parent_table: The associated table with the sharding key to be copied.
      # parent_sharding_key: The sharding key on the parent table that will be copied to `sharding_key` on `table`.
      # foreign_key: The column used to fetch the relevant record from `parent_table`.
      def install_sharding_key_assignment_trigger(**args)
        Gitlab::Database::Triggers::AssignDesiredShardingKey.new(**args.merge(connection: connection)).create
      end

      # Removes trigger used for assigning sharding keys.
      #
      # table: The table to install the trigger in.
      # sharding_key: The column to be assigned on `table`.
      # parent_table: The associated table with the sharding key to be copied.
      # parent_sharding_key: The sharding key on the parent table that will be copied to `sharding_key` on `table`.
      # foreign_key: The column used to fetch the relevant record from `parent_table`.
      def remove_sharding_key_assignment_trigger(**args)
        Gitlab::Database::Triggers::AssignDesiredShardingKey.new(**args.merge(connection: connection)).drop
      end

      # Changes the type of a column concurrently.
      #
      # table - The table containing the column.
      # column - The name of the column to change.
      # new_type - The new column type.
      def change_column_type_concurrently(table, column, new_type, type_cast_function: nil, batch_column_name: :id)
        temp_column = "#{column}_for_type_change"

        rename_column_concurrently(table, column, temp_column, type: new_type, type_cast_function: type_cast_function, batch_column_name: batch_column_name)
      end

      # Reverses operations performed by change_column_type_concurrently.
      #
      # table - The table containing the column.
      # column - The name of the column to change.
      def undo_change_column_type_concurrently(table, column)
        temp_column = "#{column}_for_type_change"

        undo_rename_column_concurrently(table, column, temp_column)
      end

      # Performs cleanup of a concurrent type change.
      #
      # table - The table containing the column.
      # column - The name of the column to change.
      # new_type - The new column type.
      def cleanup_concurrent_column_type_change(table, column, temp_column: nil)
        temp_column ||= "#{column}_for_type_change"

        transaction do
          # This has to be performed in a transaction as otherwise we might have
          # inconsistent data.
          cleanup_concurrent_column_rename(table, column, temp_column)
          rename_column(table, temp_column, column)
        end
      end

      # Reverses operations performed by cleanup_concurrent_column_type_change.
      #
      # table - The table containing the column.
      # column - The name of the column to change.
      # old_type - The type of the original column used with change_column_type_concurrently.
      # type_cast_function - Required if the conversion back to the original type is not automatic
      # batch_column_name - option for tables without a primary key, in this case
      #            another unique integer column can be used. Example: :user_id
      def undo_cleanup_concurrent_column_type_change(table, column, old_type, type_cast_function: nil, batch_column_name: :id, limit: nil, temp_column: nil)
        Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

        temp_column ||= "#{column}_for_type_change"

        # Using a descriptive name that includes orinal column's name risks
        # taking us above the 63 character limit, so we use a hash
        identifier = "#{table}_#{column}_for_type_change"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)
        temp_undo_cleanup_column = "tmp_undo_cleanup_column_#{hashed_identifier}"

        unless column_exists?(table, batch_column_name)
          raise "Column #{batch_column_name} does not exist on #{table}"
        end

        if transaction_open?
          raise 'undo_cleanup_concurrent_column_type_change can not be run inside a transaction'
        end

        check_trigger_permissions!(table)

        begin
          create_column_from(
            table,
            column,
            temp_undo_cleanup_column,
            type: old_type,
            batch_column_name: batch_column_name,
            type_cast_function: type_cast_function,
            limit: limit
          )

          transaction do
            # This has to be performed in a transaction as otherwise we might
            # have inconsistent data.
            rename_column(table, column, temp_column)
            rename_column(table, temp_undo_cleanup_column, column)

            install_rename_triggers(table, column, temp_column)
          end
        rescue StandardError
          # create_column_from can not run inside a transaction, which means
          #  that there is a risk that if any of the operations that follow it
          #  fail, we'll be left with an inconsistent schema
          # For those reasons, we make sure that we drop temp_undo_cleanup_column
          #  if an error is caught
          if column_exists?(table, temp_undo_cleanup_column)
            remove_column(table, temp_undo_cleanup_column)
          end

          raise
        end
      end

      # Cleans up a concurrent column name.
      #
      # This method takes care of removing previously installed triggers as well
      # as removing the old column.
      #
      # table - The name of the database table.
      # old - The name of the old column.
      # new - The name of the new column.
      def cleanup_concurrent_column_rename(table, old, new)
        trigger_name = rename_trigger_name(table, old, new)

        check_trigger_permissions!(table)

        remove_rename_triggers(table, trigger_name)

        remove_column(table, old)
      end

      # Reverses the operations performed by cleanup_concurrent_column_rename.
      #
      # This method adds back the old_column removed
      # by cleanup_concurrent_column_rename.
      # It also adds back the (old_column > new_column) trigger that is removed
      # by cleanup_concurrent_column_rename.
      #
      # table - The name of the database table containing the column.
      # old - The old column name.
      # new - The new column name.
      # type - The type of the old column. If no type is given the new column's
      #        type is used.
      # batch_column_name - option is for tables without primary key, in this
      #        case another unique integer column can be used. Example: :user_id
      def undo_cleanup_concurrent_column_rename(table, old, new, type: nil, batch_column_name: :id)
        unless column_exists?(table, batch_column_name)
          raise "Column #{batch_column_name} does not exist on #{table}"
        end

        if transaction_open?
          raise 'undo_cleanup_concurrent_column_rename can not be run inside a transaction'
        end

        check_trigger_permissions!(table)

        create_column_from(table, new, old, type: type, batch_column_name: batch_column_name)

        install_rename_triggers(table, old, new)
      end

      def convert_to_type_column(column, from_type, to_type)
        "#{column}_convert_#{from_type}_to_#{to_type}"
      end

      def convert_to_bigint_column(column)
        "#{column}_convert_to_bigint"
      end

      # Initializes the conversion of a set of integer columns to bigint
      #
      # It can be used for converting both a Primary Key and any Foreign Keys
      # that may reference it or any other integer column that we may want to
      # upgrade (e.g. columns that store IDs, but are not set as FKs).
      #
      # - For primary keys and Foreign Keys (or other columns) defined as NOT NULL,
      #    the new bigint column is added with a hardcoded NOT NULL DEFAULT 0
      #    which allows us to skip a very costly verification step once we
      #    are ready to switch it.
      #   This is crucial for Primary Key conversions, because setting a column
      #    as the PK converts even check constraints to NOT NULL constraints
      #    and forces an inline re-verification of the whole table.
      # - It sets up a trigger to keep the two columns in sync.
      #
      #   Note: this helper is intended to be used in a regular (pre-deployment) migration.
      #
      #   This helper is part 1 of a multi-step migration process:
      #   1. initialize_conversion_of_integer_to_bigint to create the new columns and database trigger
      #   2. backfill_conversion_of_integer_to_bigint to copy historic data using background migrations
      #   3. remaining steps TBD, see #288005
      #
      # table - The name of the database table containing the column
      # columns - The name, or array of names, of the column(s) that we want to convert to bigint.
      # primary_key - The name of the primary key column (most often :id)
      def initialize_conversion_of_integer_to_bigint(table, columns, primary_key: :id) # rubocop:disable Lint/UnusedMethodArgument -- for backward compatibility, don't remove primary_key
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .init
      end

      # Reverts `initialize_conversion_of_integer_to_bigint`
      #
      # table - The name of the database table containing the columns
      # columns - The name, or array of names, of the column(s) that we're converting to bigint.
      def revert_initialize_conversion_of_integer_to_bigint(table, columns)
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .revert_init
      end

      # Similar to `revert_initialize_conversion_of_integer_to_bigint`,
      # but `cleanup_conversion_of_integer_to_bigint` updates the yaml file
      def cleanup_conversion_of_integer_to_bigint(table, columns)
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .cleanup
      end

      # Reverts `cleanup_conversion_of_integer_to_bigint`
      #
      # table - The name of the database table containing the columns
      # columns - The name, or array of names, of the column(s) that we have converted to bigint.
      # primary_key - The name of the primary key column (most often :id)
      def restore_conversion_of_integer_to_bigint(table, columns, primary_key: :id) # rubocop:disable Lint/UnusedMethodArgument -- for backward compatibility, don't remove primary_key
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .restore_cleanup
      end

      # Backfills the new columns used in an integer-to-bigint conversion using background migrations.
      #
      # - This helper should be called from a post-deployment migration.
      # - In order for this helper to work properly,  the new columns must be first initialized with
      #   the `initialize_conversion_of_integer_to_bigint` helper.
      # - It tracks the scheduled background jobs through Gitlab::Database::BackgroundMigration::BatchedMigration,
      #   which allows a more thorough check that all jobs succeeded in the
      #   cleanup migration and is way faster for very large tables.
      #
      #   Note: this helper is intended to be used in a post-deployment migration, to ensure any new code is
      #   deployed (including background job changes) before we begin processing the background migration.
      #
      #   This helper is part 2 of a multi-step migration process:
      #   1. initialize_conversion_of_integer_to_bigint to create the new columns and database trigger
      #   2. backfill_conversion_of_integer_to_bigint to copy historic data using background migrations
      #   3. remaining steps TBD, see #288005
      #
      # table - The name of the database table containing the column
      # columns - The name, or an array of names, of the column(s) we want to convert to bigint.
      # primary_key - The name of the primary key column (most often :id)
      # batch_size - The number of rows to schedule in a single background migration
      # sub_batch_size - The smaller batches that will be used by each scheduled job
      #   to update the table. Useful to keep each update at ~100ms while executing
      #   more updates per interval (2.minutes)
      #   Note that each execution of a sub-batch adds a constant 100ms sleep
      #    time in between the updates, which must be taken into account
      #    while calculating the batch, sub_batch and interval values.
      # interval - The time interval between every background migration
      #
      # example:
      # Assume that we have figured out that updating 200 records of the events
      #  table takes ~100ms on average.
      # We can set the sub_batch_size to 200, leave the interval to the default
      #  and set the batch_size to 50_000 which will require
      #  ~50s = (50000 / 200) * (0.1 + 0.1) to complete and leaves breathing space
      #  between the scheduled jobs
      def backfill_conversion_of_integer_to_bigint(
        table,
        columns,
        primary_key: :id,
        batch_size: 20_000,
        sub_batch_size: 1000,
        pause_ms: 100,
        interval: 2.minutes
      )
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .backfill(
            primary_key: primary_key,
            batch_size: batch_size,
            sub_batch_size: sub_batch_size,
            pause_ms: pause_ms,
            job_interval: interval
          )
      end

      # Handy helper to ensure data finalization for bigint conversion process
      def ensure_backfill_conversion_of_integer_to_bigint_is_finished(table, columns, primary_key: :id)
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .ensure_backfill(primary_key: primary_key)
      end

      # Reverts `backfill_conversion_of_integer_to_bigint`
      #
      # table - The name of the database table containing the column
      # columns - The name, or an array of names, of the column(s) we want to convert to bigint.
      # primary_key - The name of the primary key column (most often :id)
      def revert_backfill_conversion_of_integer_to_bigint(table, columns, primary_key: :id)
        Gitlab::Database::Migrations::Conversions::BigintConverter
          .new(self, table, columns)
          .revert_backfill(primary_key: primary_key)
      end

      # Returns an Array containing the indexes for the given column
      def indexes_for(table, column)
        column = column.to_s

        indexes(table).select { |index| index.columns.include?(column) }
      end

      # Returns an Array containing the foreign keys for the given column.
      def foreign_keys_for(table, column)
        column = column.to_s

        foreign_keys(table).select { |fk| fk.column == column }
      end

      # Copies all indexes for the old column to a new column.
      #
      # table - The table containing the columns and indexes.
      # old - The old column.
      # new - The new column.
      def copy_indexes(table, old, new)
        old = old.to_s
        new = new.to_s

        indexes_for(table, old).each do |index|
          new_columns = index.columns.map do |column|
            column == old ? new : column
          end

          # This is necessary as we can't properly rename indexes such as
          # "ci_taggings_idx".
          unless index.name.include?(old)
            raise "The index #{index.name} can not be copied as it does not "\
              "mention the old column. You have to rename this index manually first."
          end

          name = index.name.gsub(old, new)

          if name.length > 63
            digest = Digest::SHA256.hexdigest(name).first(10)
            name = "idx_copy_#{digest}"
          end

          options = {
            unique: index.unique,
            name: name,
            length: index.lengths,
            order: index.orders
          }

          options[:using] = index.using if index.using
          options[:where] = index.where if index.where

          unless index.opclasses.blank?
            opclasses = index.opclasses.dup

            # Copy the operator classes for the old column (if any) to the new
            # column.
            opclasses[new] = opclasses.delete(old) if opclasses[old]

            options[:opclass] = opclasses
          end

          add_concurrent_index(table, new_columns, options)
        end
      end

      # Copies all foreign keys for the old column to the new column.
      #
      # table - The table containing the columns and indexes.
      # old - The old column.
      # new - The new column.
      def copy_foreign_keys(table, old, new)
        foreign_keys_for(table, old).each do |fk|
          add_concurrent_foreign_key(fk.from_table,
            fk.to_table,
            column: new,
            on_delete: fk.on_delete)
        end
      end

      # Returns the column for the given table and column name.
      def column_for(table, name)
        name = name.to_s

        column = columns(table).find { |column| column.name == name }
        raise(missing_schema_object_message(table, "column", name)) if column.nil?

        column
      end

      # This will replace the first occurrence of a string in a column with
      # the replacement using `regexp_replace`
      def replace_sql(column, pattern, replacement)
        quoted_pattern = Arel::Nodes::Quoted.new(pattern.to_s)
        quoted_replacement = Arel::Nodes::Quoted.new(replacement.to_s)

        replace = Arel::Nodes::NamedFunction.new(
          "regexp_replace", [column, quoted_pattern, quoted_replacement]
        )

        Arel::Nodes::SqlLiteral.new(replace.to_sql)
      end

      def remove_foreign_key_if_exists(source, target = nil, **kwargs)
        reverse_lock_order = kwargs.delete(:reverse_lock_order)
        return unless foreign_key_exists?(source, target, **kwargs)

        if target && reverse_lock_order && transaction_open?
          execute("LOCK TABLE #{target}, #{source} IN ACCESS EXCLUSIVE MODE")
        end

        if target
          remove_foreign_key(source, target, **kwargs)
        else
          remove_foreign_key(source, **kwargs)
        end
      end

      def remove_foreign_key_without_error(*args, **kwargs)
        remove_foreign_key(*args, **kwargs)
      rescue ArgumentError
      end

      def check_trigger_permissions!(table)
        unless Grant.create_and_execute_trigger?(table)
          dbname = ApplicationRecord.database.database_name
          user = ApplicationRecord.database.username

          raise <<-EOF
Your database user is not allowed to create, drop, or execute triggers on the
table #{table}.

If you are using PostgreSQL you can solve this by logging in to the GitLab
database (#{dbname}) using a super user and running:

    ALTER #{user} WITH SUPERUSER

This query will grant the user super user permissions, ensuring you don't run
into similar problems in the future (e.g. when new tables are created).
          EOF
        end
      end

      # Fetches indexes on a column by name for postgres.
      #
      # This will include indexes using an expression on the column, for example:
      # `CREATE INDEX CONCURRENTLY index_name ON table (LOWER(column));`
      #
      # We can remove this when upgrading to Rails 5 with an updated `index_exists?`:
      # - https://github.com/rails/rails/commit/edc2b7718725016e988089b5fb6d6fb9d6e16882
      #
      # Or this can be removed when we no longer support postgres < 9.5, so we
      # can use `CREATE INDEX IF NOT EXISTS`.
      def index_exists_by_name?(table, index)
        # We can't fall back to the normal `index_exists?` method because that
        # does not find indexes without passing a column name.
        if indexes(table).map(&:name).include?(index.to_s)
          true
        else
          postgres_exists_by_name?(table, index)
        end
      end

      def postgres_exists_by_name?(table, name)
        index_sql = <<~SQL
          SELECT COUNT(*)
          FROM pg_catalog.pg_indexes
          WHERE schemaname = #{connection.quote(current_schema)}
            AND tablename = #{connection.quote(table)}
            AND indexname = #{connection.quote(name)}
        SQL

        connection.select_value(index_sql).to_i > 0
      end

      def create_or_update_plan_limit(limit_name, plan_name, limit_value)
        limit_name_quoted = quote_column_name(limit_name)
        plan_name_quoted = quote(plan_name)
        limit_value_quoted = quote(limit_value)

        execute <<~SQL
          INSERT INTO plan_limits (plan_id, #{limit_name_quoted})
          SELECT id, #{limit_value_quoted} FROM plans WHERE name = #{plan_name_quoted} LIMIT 1
          ON CONFLICT (plan_id) DO UPDATE SET #{limit_name_quoted} = EXCLUDED.#{limit_name_quoted};
        SQL
      end

      # Note this should only be used with very small tables
      def backfill_iids(table)
        sql = <<-END
          UPDATE #{table}
          SET iid = #{table}_with_calculated_iid.iid_num
          FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY project_id ORDER BY id ASC) AS iid_num FROM #{table}
          ) AS #{table}_with_calculated_iid
          WHERE #{table}.id = #{table}_with_calculated_iid.id
        END

        execute(sql)
      end

      def add_primary_key_using_index(table_name, pk_name, index_to_use)
        execute <<~SQL
          ALTER TABLE #{quote_table_name(table_name)} ADD CONSTRAINT #{quote_table_name(pk_name)} PRIMARY KEY USING INDEX #{quote_table_name(index_to_use)}
        SQL
      end

      def swap_primary_key(table_name, primary_key_name, index_to_use)
        with_lock_retries(raise_on_exhaustion: true) do
          drop_constraint(table_name, primary_key_name, cascade: true)
          add_primary_key_using_index(table_name, primary_key_name, index_to_use)
        end
      end
      alias_method :unswap_primary_key, :swap_primary_key

      def drop_sequence(table_name, column_name, sequence_name)
        execute <<~SQL
          ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} DROP DEFAULT;
          DROP SEQUENCE IF EXISTS #{quote_table_name(sequence_name)}
        SQL
      end

      def add_sequence(table_name, column_name, sequence_name, start_value)
        execute <<~SQL
          CREATE SEQUENCE #{quote_table_name(sequence_name)} START #{start_value};
          ALTER TABLE #{quote_table_name(table_name)} ALTER COLUMN #{quote_column_name(column_name)} SET DEFAULT nextval(#{quote(sequence_name)})
        SQL
      end

      # While it is safe to call `change_column_default` on a column without
      # default it would still require access exclusive lock on the table
      # and for tables with high autovacuum(wraparound prevention) it will
      # fail if their executions overlap.
      #
      def remove_column_default(table_name, column_name)
        column = connection.columns(table_name).find { |col| col.name == column_name.to_s }

        if column.default || column.default_function
          change_column_default(table_name, column_name, to: nil)
        end
      end

      def lock_tables(*tables, mode: :access_exclusive, only: nil, nowait: nil)
        only_param = only && 'ONLY'
        nowait_param = nowait && 'NOWAIT'
        tables_param = tables.map { |t| quote_table_name(t) }.join(', ')
        mode_param = mode.to_s.upcase.tr('_', ' ')

        execute(<<~SQL.squish)
          LOCK TABLE #{only_param} #{tables_param} IN #{mode_param} MODE #{nowait_param}
        SQL
      end

      def table_integer_ids
        YAML.safe_load_file(File.join(INTEGER_IDS_YET_TO_INITIALIZED_TO_BIGINT_FILE_PATH))
      end

      private

      def multiple_columns(columns, separator: ', ')
        Array.wrap(columns).join(separator)
      end

      def cascade_statement(cascade)
        cascade ? 'CASCADE' : ''
      end

      def validate_check_constraint_name!(constraint_name)
        if constraint_name.to_s.length > MAX_IDENTIFIER_NAME_LENGTH
          raise "The maximum allowed constraint name is #{MAX_IDENTIFIER_NAME_LENGTH} characters"
        end
      end

      # mappings => {} where keys are column names and values are hashes with the following keys:
      # from_type - from which type we're migrating
      # to_type - to which type we're migrating
      # default_value - custom default value, if not provided will be taken from neutral_values_for_type
      def mapping_has_required_columns?(mapping)
        %i[from_type to_type].map do |required_key|
          mapping.has_key?(required_key)
        end.all?
      end

      def column_is_nullable?(table, column)
        table_name, schema_name = table.to_s.split('.').reverse
        schema_name ||= current_schema

        # Check if table.column has not been defined with NOT NULL
        check_sql = <<~SQL
          SELECT c.is_nullable
          FROM information_schema.columns c
          WHERE c.table_schema = #{connection.quote(schema_name)}
            AND c.table_name = #{connection.quote(table_name)}
            AND c.column_name = #{connection.quote(column)}
        SQL

        connection.select_value(check_sql) == 'YES'
      end

      def missing_schema_object_message(table, type, name)
        <<~MESSAGE
          Could not find #{type} "#{name}" on table "#{table}" which was referenced during the migration.
          This issue could be caused by the database schema straying from the expected state.

          To resolve this issue, please verify:
            1. all previous migrations have completed
            2. the database objects used in this migration match the Rails definition in schema.rb or structure.sql

        MESSAGE
      end

      def tables_match?(target_table, foreign_key_table)
        target_table.blank? || foreign_key_table == target_table
      end

      def options_match?(foreign_key_options, options)
        options.all? { |k, v| foreign_key_options[k].to_s == v.to_s }
      end

      def on_delete_statement(on_delete)
        return '' if on_delete.blank?
        return 'ON DELETE SET NULL' if on_delete == :nullify

        "ON DELETE #{on_delete.upcase}"
      end

      def on_update_statement(on_update)
        return '' if on_update.blank?
        return 'ON UPDATE SET NULL' if on_update == :nullify

        "ON UPDATE #{on_update.upcase}"
      end

      def create_column_from(table, old, new, type: nil, batch_column_name: :id, type_cast_function: nil, limit: nil)
        old_col = column_for(table, old)
        new_type = type || old_col.type
        new_limit = limit || old_col.limit

        add_column(table, new, new_type,
          limit: new_limit,
          precision: old_col.precision,
          scale: old_col.scale)

        # We set the default value _after_ adding the column so we don't end up
        # updating any existing data with the default value. This isn't
        # necessary since we copy over old values further down.
        change_column_default(table, new, old_col.default) unless old_col.default.nil?

        old_value = Arel::Table.new(table)[old]

        if type_cast_function.present?
          old_value = Arel::Nodes::NamedFunction.new(type_cast_function, [old_value])
        end

        Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
          Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
            update_column_in_batches(table, new, old_value, batch_column_name: batch_column_name, disable_lock_writes: true)
          end
        end

        add_not_null_constraint(table, new) unless old_col.null

        copy_indexes(table, old, new)
        copy_foreign_keys(table, old, new)
        copy_check_constraints(table, old, new)
      end

      def validate_timestamp_column_name!(column_name)
        return if column_name.to_s.end_with?('_at')

        raise <<~MESSAGE
          Illegal timestamp column name! Got #{column_name}.
          Must end with `_at`}
        MESSAGE
      end

      def execute_add_concurrent_foreign_key(source, target, options)
        # Using NOT VALID allows us to create a key without immediately
        # validating it. This means we keep the ALTER TABLE lock only for a
        # short period of time. The key _is_ enforced for any newly created
        # data.
        not_valid = 'NOT VALID'
        lock_mode = 'SHARE ROW EXCLUSIVE'

        if table_partitioned?(source)
          not_valid = ''
          lock_mode = 'ACCESS EXCLUSIVE'
        end

        with_lock_retries do
          execute("LOCK TABLE #{target}, #{source} IN #{lock_mode} MODE") if options[:reverse_lock_order]
          execute(<<~SQL.squish)
            ALTER TABLE #{source}
            ADD CONSTRAINT #{options[:name]}
            FOREIGN KEY (#{multiple_columns(options[:column])})
            REFERENCES #{target} (#{multiple_columns(options[:target_column])})
            #{on_update_statement(options[:on_update])}
            #{on_delete_statement(options[:on_delete])}
            #{not_valid};
          SQL
        end
      end
    end
  end
end
