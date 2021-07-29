# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      include Migrations::BackgroundMigrationHelpers
      include DynamicModelHelpers
      include RenameTableHelpers

      # https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS
      MAX_IDENTIFIER_NAME_LENGTH = 63

      PERMITTED_TIMESTAMP_COLUMNS = %i[created_at updated_at deleted_at].to_set.freeze
      DEFAULT_TIMESTAMP_COLUMNS = %i[created_at updated_at].freeze

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
      #  :columns - the column names to create. Must be one
      #             of `Gitlab::Database::MigrationHelpers::PERMITTED_TIMESTAMP_COLUMNS`.
      #             Default value: `DEFAULT_TIMESTAMP_COLUMNS`
      #
      # All options are optional.
      def add_timestamps_with_timezone(table_name, options = {})
        options[:null] = false if options[:null].nil?
        columns = options.fetch(:columns, DEFAULT_TIMESTAMP_COLUMNS)
        default_value = options[:default]

        validate_not_in_transaction!(:add_timestamps_with_timezone, 'with default value') if default_value

        columns.each do |column_name|
          validate_timestamp_column_name!(column_name)

          # If default value is presented, use `add_column_with_default` method instead.
          if default_value
            add_column_with_default(
              table_name,
              column_name,
              :datetime_with_timezone,
              default: default_value,
              allow_null: options[:null]
            )
          else
            add_column(table_name, column_name, :datetime_with_timezone, **options)
          end
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

      #
      # Creates a new table, optionally allowing the caller to add check constraints to the table.
      # Aside from that addition, this method should behave identically to Rails' `create_table` method.
      #
      # Example:
      #
      #     create_table_with_constraints :some_table do |t|
      #       t.integer :thing, null: false
      #       t.text :other_thing
      #
      #       t.check_constraint :thing_is_not_null, 'thing IS NOT NULL'
      #       t.text_limit :other_thing, 255
      #     end
      #
      # See Rails' `create_table` for more info on the available arguments.
      def create_table_with_constraints(table_name, **options, &block)
        helper_context = self

        with_lock_retries do
          check_constraints = []

          create_table(table_name, **options) do |t|
            t.define_singleton_method(:check_constraint) do |name, definition|
              helper_context.send(:validate_check_constraint_name!, name) # rubocop:disable GitlabSecurity/PublicSend

              check_constraints << { name: name, definition: definition }
            end

            t.define_singleton_method(:text_limit) do |column_name, limit, name: nil|
              # rubocop:disable GitlabSecurity/PublicSend
              name = helper_context.send(:text_limit_name, table_name, column_name, name: name)
              helper_context.send(:validate_check_constraint_name!, name)
              # rubocop:enable GitlabSecurity/PublicSend

              column_name = helper_context.quote_column_name(column_name)
              definition = "char_length(#{column_name}) <= #{limit}"

              check_constraints << { name: name, definition: definition }
            end

            t.instance_eval(&block) unless block.nil?
          end

          next if check_constraints.empty?

          constraint_clauses = check_constraints.map do |constraint|
            "ADD CONSTRAINT #{quote_table_name(constraint[:name])} CHECK (#{constraint[:definition]})"
          end

          execute(<<~SQL)
            ALTER TABLE #{quote_table_name(table_name)}
            #{constraint_clauses.join(",\n")}
          SQL
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

        options = options.merge({ algorithm: :concurrently })

        if index_exists?(table_name, column_name, **options)
          Gitlab::AppLogger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
          return
        end

        disable_statement_timeout do
          add_index(table_name, column_name, **options)
        end
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

        options = options.merge({ algorithm: :concurrently })

        unless index_exists?(table_name, column_name, **options)
          Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
          return
        end

        disable_statement_timeout do
          remove_index(table_name, **options.merge({ column: column_name }))
        end
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
      # name - The name of the foreign key.
      #
      def add_concurrent_foreign_key(source, target, column:, on_delete: :cascade, target_column: :id, name: nil, validate: true)
        # Transactions would result in ALTER TABLE locks being held for the
        # duration of the transaction, defeating the purpose of this method.
        if transaction_open?
          raise 'add_concurrent_foreign_key can not be run inside a transaction'
        end

        options = {
          column: column,
          on_delete: on_delete,
          name: name.presence || concurrent_foreign_key_name(source, column),
          primary_key: target_column
        }

        if foreign_key_exists?(source, target, **options)
          warning_message = "Foreign key not created because it exists already " \
            "(this may be due to an aborted migration or similar): " \
            "source: #{source}, target: #{target}, column: #{options[:column]}, "\
            "name: #{options[:name]}, on_delete: #{options[:on_delete]}"

          Gitlab::AppLogger.warn warning_message
        else
          # Using NOT VALID allows us to create a key without immediately
          # validating it. This means we keep the ALTER TABLE lock only for a
          # short period of time. The key _is_ enforced for any newly created
          # data.

          with_lock_retries do
            execute <<-EOF.strip_heredoc
            ALTER TABLE #{source}
            ADD CONSTRAINT #{options[:name]}
            FOREIGN KEY (#{options[:column]})
            REFERENCES #{target} (#{target_column})
            #{on_delete_statement(options[:on_delete])}
            NOT VALID;
            EOF
          end
        end

        # Validate the existing constraint. This can potentially take a very
        # long time to complete, but fortunately does not lock the source table
        # while running.
        # Disable this check by passing `validate: false` to the method call
        # The check will be enforced for new data (inserts) coming in,
        # but validating existing data is delayed.
        #
        # Note this is a no-op in case the constraint is VALID already

        if validate
          disable_statement_timeout do
            execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{options[:name]};")
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
        foreign_keys(source).any? do |foreign_key|
          tables_match?(target.to_s, foreign_key.to_table.to_s) &&
            options_match?(foreign_key.options, options)
        end
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
        identifier = "#{table}_#{column}_fk"
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

        "#{prefix}#{hashed_identifier}"
      end

      # Long-running migrations may take more than the timeout allowed by
      # the database. Disable the session's statement timeout to ensure
      # migrations don't get killed prematurely.
      #
      # There are two possible ways to disable the statement timeout:
      #
      # - Per transaction (this is the preferred and default mode)
      # - Per connection (requires a cleanup after the execution)
      #
      # When using a per connection disable statement, code must be inside
      # a block so we can automatically execute `RESET ALL` after block finishes
      # otherwise the statement will still be disabled until connection is dropped
      # or `RESET ALL` is executed
      def disable_statement_timeout
        if block_given?
          if statement_timeout_disabled?
            # Don't do anything if the statement_timeout is already disabled
            # Allows for nested calls of disable_statement_timeout without
            # resetting the timeout too early (before the outer call ends)
            yield
          else
            begin
              execute('SET statement_timeout TO 0')

              yield
            ensure
              execute('RESET ALL')
            end
          end
        else
          unless transaction_open?
            raise <<~ERROR
              Cannot call disable_statement_timeout() without a transaction open or outside of a transaction block.
              If you don't want to use a transaction wrap your code in a block call:

              disable_statement_timeout { # code that requires disabled statement here }

              This will make sure statement_timeout is disabled before and reset after the block execution is finished.
            ERROR
          end

          execute('SET LOCAL statement_timeout TO 0')
        end
      end

      # Executes the block with a retry mechanism that alters the +lock_timeout+ and +sleep_time+ between attempts.
      # The timings can be controlled via the +timing_configuration+ parameter.
      # If the lock was not acquired within the retry period, a last attempt is made without using +lock_timeout+.
      #
      # ==== Examples
      #   # Invoking without parameters
      #   with_lock_retries do
      #     drop_table :my_table
      #   end
      #
      #   # Invoking with custom +timing_configuration+
      #   t = [
      #     [1.second, 1.second],
      #     [2.seconds, 2.seconds]
      #   ]
      #
      #   with_lock_retries(timing_configuration: t) do
      #     drop_table :my_table # this will be retried twice
      #   end
      #
      #   # Disabling the retries using an environment variable
      #   > export DISABLE_LOCK_RETRIES=true
      #
      #   with_lock_retries do
      #     drop_table :my_table # one invocation, it will not retry at all
      #   end
      #
      # ==== Parameters
      # * +timing_configuration+ - [[ActiveSupport::Duration, ActiveSupport::Duration], ...] lock timeout for the block, sleep time before the next iteration, defaults to `Gitlab::Database::WithLockRetries::DEFAULT_TIMING_CONFIGURATION`
      # * +logger+ - [Gitlab::JsonLogger]
      # * +env+ - [Hash] custom environment hash, see the example with `DISABLE_LOCK_RETRIES`
      def with_lock_retries(*args, **kwargs, &block)
        raise_on_exhaustion = !!kwargs.delete(:raise_on_exhaustion)
        merged_args = {
          klass: self.class,
          logger: Gitlab::BackgroundMigration::Logger
        }.merge(kwargs)

        Gitlab::Database::WithLockRetries.new(**merged_args)
          .run(raise_on_exhaustion: raise_on_exhaustion, &block)
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
      def update_column_in_batches(table, column, value, batch_size: nil, batch_column_name: :id)
        if transaction_open?
          raise 'update_column_in_batches can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        table = Arel::Table.new(table)

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

          execute(update_arel.to_sql)

          # There are no more rows left to update.
          break unless stop_row
        end
      end

      # Adds a column with a default value without locking an entire table.
      #
      # @deprecated With PostgreSQL 11, adding columns with a default does not lead to a table rewrite anymore.
      #             As such, this method is not needed anymore and the default `add_column` helper should be used.
      #             This helper is subject to be removed in a >13.0 release.
      def add_column_with_default(table, column, type, default:, limit: nil, allow_null: false)
        raise 'Deprecated: add_column_with_default does not support being passed blocks anymore' if block_given?

        add_column(table, column, type, default: default, limit: limit, null: allow_null)
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
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table).create(old, new, trigger_name: trigger_name)
      end

      # Removes the triggers used for renaming a column concurrently.
      def remove_rename_triggers(table, trigger)
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table).drop(trigger)
      end

      # Returns the (base) name to use for triggers when renaming columns.
      def rename_trigger_name(table, old, new)
        Gitlab::Database::UnidirectionalCopyTrigger.on_table(table).name(old, new)
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
      def cleanup_concurrent_column_type_change(table, column)
        temp_column = "#{column}_for_type_change"

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
      def undo_cleanup_concurrent_column_type_change(table, column, old_type, type_cast_function: nil, batch_column_name: :id, limit: nil)
        temp_column = "#{column}_for_type_change"

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

      # Changes the column type of a table using a background migration.
      #
      # Because this method uses a background migration it's more suitable for
      # large tables. For small tables it's better to use
      # `change_column_type_concurrently` since it can complete its work in a
      # much shorter amount of time and doesn't rely on Sidekiq.
      #
      # Example usage:
      #
      #     class Issue < ActiveRecord::Base
      #       self.table_name = 'issues'
      #
      #       include EachBatch
      #
      #       def self.to_migrate
      #         where('closed_at IS NOT NULL')
      #       end
      #     end
      #
      #     change_column_type_using_background_migration(
      #       Issue.to_migrate,
      #       :closed_at,
      #       :datetime_with_timezone
      #     )
      #
      # Reverting a migration like this is done exactly the same way, just with
      # a different type to migrate to (e.g. `:datetime` in the above example).
      #
      # relation - An ActiveRecord relation to use for scheduling jobs and
      #            figuring out what table we're modifying. This relation _must_
      #            have the EachBatch module included.
      #
      # column - The name of the column for which the type will be changed.
      #
      # new_type - The new type of the column.
      #
      # batch_size - The number of rows to schedule in a single background
      #              migration.
      #
      # interval - The time interval between every background migration.
      def change_column_type_using_background_migration(
        relation,
        column,
        new_type,
        batch_size: 10_000,
        interval: 10.minutes
      )

        unless relation.model < EachBatch
          raise TypeError, 'The relation must include the EachBatch module'
        end

        temp_column = "#{column}_for_type_change"
        table = relation.table_name
        max_index = 0

        add_column(table, temp_column, new_type)
        install_rename_triggers(table, column, temp_column)

        # Schedule the jobs that will copy the data from the old column to the
        # new one. Rows with NULL values in our source column are skipped since
        # the target column is already NULL at this point.
        relation.where.not(column => nil).each_batch(of: batch_size) do |batch, index|
          start_id, end_id = batch.pluck('MIN(id), MAX(id)').first
          max_index = index

          migrate_in(
            index * interval,
            'CopyColumn',
            [table, column, temp_column, start_id, end_id]
          )
        end

        # Schedule the renaming of the column to happen (initially) 1 hour after
        # the last batch finished.
        migrate_in(
          (max_index * interval) + 1.hour,
          'CleanupConcurrentTypeChange',
          [table, column, temp_column]
        )

        if perform_background_migration_inline?
          # To ensure the schema is up to date immediately we perform the
          # migration inline in dev / test environments.
          Gitlab::BackgroundMigration.steal('CopyColumn')
          Gitlab::BackgroundMigration.steal('CleanupConcurrentTypeChange')
        end
      end

      # Renames a column using a background migration.
      #
      # Because this method uses a background migration it's more suitable for
      # large tables. For small tables it's better to use
      # `rename_column_concurrently` since it can complete its work in a much
      # shorter amount of time and doesn't rely on Sidekiq.
      #
      # Example usage:
      #
      #     rename_column_using_background_migration(
      #       :users,
      #       :feed_token,
      #       :rss_token
      #     )
      #
      # table - The name of the database table containing the column.
      #
      # old - The old column name.
      #
      # new - The new column name.
      #
      # type - The type of the new column. If no type is given the old column's
      #        type is used.
      #
      # batch_size - The number of rows to schedule in a single background
      #              migration.
      #
      # interval - The time interval between every background migration.
      def rename_column_using_background_migration(
        table,
        old_column,
        new_column,
        type: nil,
        batch_size: 10_000,
        interval: 10.minutes
      )

        check_trigger_permissions!(table)

        old_col = column_for(table, old_column)
        new_type = type || old_col.type
        max_index = 0

        add_column(table, new_column, new_type,
                   limit: old_col.limit,
                   precision: old_col.precision,
                   scale: old_col.scale)

        # We set the default value _after_ adding the column so we don't end up
        # updating any existing data with the default value. This isn't
        # necessary since we copy over old values further down.
        change_column_default(table, new_column, old_col.default) if old_col.default

        install_rename_triggers(table, old_column, new_column)

        model = Class.new(ActiveRecord::Base) do
          self.table_name = table

          include ::EachBatch
        end

        # Schedule the jobs that will copy the data from the old column to the
        # new one. Rows with NULL values in our source column are skipped since
        # the target column is already NULL at this point.
        model.where.not(old_column => nil).each_batch(of: batch_size) do |batch, index|
          start_id, end_id = batch.pluck('MIN(id), MAX(id)').first
          max_index = index

          migrate_in(
            index * interval,
            'CopyColumn',
            [table, old_column, new_column, start_id, end_id]
          )
        end

        # Schedule the renaming of the column to happen (initially) 1 hour after
        # the last batch finished.
        migrate_in(
          (max_index * interval) + 1.hour,
          'CleanupConcurrentRename',
          [table, old_column, new_column]
        )

        if perform_background_migration_inline?
          # To ensure the schema is up to date immediately we perform the
          # migration inline in dev / test environments.
          Gitlab::BackgroundMigration.steal('CopyColumn')
          Gitlab::BackgroundMigration.steal('CleanupConcurrentRename')
        end
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
      def initialize_conversion_of_integer_to_bigint(table, columns, primary_key: :id)
        unless table_exists?(table)
          raise "Table #{table} does not exist"
        end

        unless column_exists?(table, primary_key)
          raise "Column #{primary_key} does not exist on #{table}"
        end

        columns = Array.wrap(columns)
        columns.each do |column|
          next if column_exists?(table, column)

          raise ArgumentError, "Column #{column} does not exist on #{table}"
        end

        check_trigger_permissions!(table)

        conversions = columns.to_h { |column| [column, convert_to_bigint_column(column)] }

        with_lock_retries do
          conversions.each do |(source_column, temporary_name)|
            column = column_for(table, source_column)

            if (column.name.to_s == primary_key.to_s) || !column.null
              # If the column to be converted is either a PK or is defined as NOT NULL,
              # set it to `NOT NULL DEFAULT 0` and we'll copy paste the correct values bellow
              # That way, we skip the expensive validation step required to add
              #  a NOT NULL constraint at the end of the process
              add_column(table, temporary_name, :bigint, default: column.default || 0, null: false)
            else
              add_column(table, temporary_name, :bigint, default: column.default)
            end
          end

          install_rename_triggers(table, conversions.keys, conversions.values)
        end
      end

      # Reverts `initialize_conversion_of_integer_to_bigint`
      #
      # table - The name of the database table containing the columns
      # columns - The name, or array of names, of the column(s) that we're converting to bigint.
      def revert_initialize_conversion_of_integer_to_bigint(table, columns)
        columns = Array.wrap(columns)
        temporary_columns = columns.map { |column| convert_to_bigint_column(column) }

        trigger_name = rename_trigger_name(table, columns, temporary_columns)
        remove_rename_triggers(table, trigger_name)

        temporary_columns.each { |column| remove_column(table, column) }
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
        interval: 2.minutes
      )

        unless table_exists?(table)
          raise "Table #{table} does not exist"
        end

        unless column_exists?(table, primary_key)
          raise "Column #{primary_key} does not exist on #{table}"
        end

        conversions = Array.wrap(columns).to_h do |column|
          raise ArgumentError, "Column #{column} does not exist on #{table}" unless column_exists?(table, column)

          temporary_name = convert_to_bigint_column(column)
          raise ArgumentError, "Column #{temporary_name} does not exist on #{table}" unless column_exists?(table, temporary_name)

          [column, temporary_name]
        end

        queue_batched_background_migration(
          'CopyColumnUsingBackgroundMigrationJob',
          table,
          primary_key,
          conversions.keys,
          conversions.values,
          job_interval: interval,
          batch_size: batch_size,
          sub_batch_size: sub_batch_size)
      end

      # Reverts `backfill_conversion_of_integer_to_bigint`
      #
      # table - The name of the database table containing the column
      # columns - The name, or an array of names, of the column(s) we want to convert to bigint.
      # primary_key - The name of the primary key column (most often :id)
      def revert_backfill_conversion_of_integer_to_bigint(table, columns, primary_key: :id)
        columns = Array.wrap(columns)

        conditions = ActiveRecord::Base.sanitize_sql([
          'job_class_name = :job_class_name AND table_name = :table_name AND column_name = :column_name AND job_arguments = :job_arguments',
          job_class_name: 'CopyColumnUsingBackgroundMigrationJob',
          table_name: table,
          column_name: primary_key,
          job_arguments: [columns, columns.map { |column| convert_to_bigint_column(column) }].to_json
        ])

        execute("DELETE FROM batched_background_migrations WHERE #{conditions}")
      end

      def ensure_batched_background_migration_is_finished(job_class_name:, table_name:, column_name:, job_arguments:)
        migration = Gitlab::Database::BackgroundMigration::BatchedMigration
          .for_configuration(job_class_name, table_name, column_name, job_arguments).first

        configuration = {
          job_class_name: job_class_name,
          table_name: table_name,
          column_name: column_name,
          job_arguments: job_arguments
        }

        if migration.nil?
          Gitlab::AppLogger.warn "Could not find batched background migration for the given configuration: #{configuration}"
        elsif !migration.finished?
          raise "Expected batched background migration for the given configuration to be marked as 'finished', " \
            "but it is '#{migration.status}':" \
            "\t#{configuration}" \
            "\n\n" \
            "Finalize it manualy by running" \
            "\n\n" \
            "\tsudo gitlab-rake gitlab:background_migrations:finalize[#{job_class_name},#{table_name},#{column_name},'#{job_arguments.inspect.gsub(',', '\,')}']" \
            "\n\n" \
            "For more information, check the documentation" \
            "\n\n" \
            "\thttps://docs.gitlab.com/ee/user/admin_area/monitoring/background_migrations.html#database-migrations-failing-because-of-batched-background-migration-not-finished"
        end
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

      def remove_foreign_key_if_exists(...)
        if foreign_key_exists?(...)
          remove_foreign_key(...)
        end
      end

      def remove_foreign_key_without_error(*args, **kwargs)
        remove_foreign_key(*args, **kwargs)
      rescue ArgumentError
      end

      def sidekiq_queue_migrate(queue_from, to:)
        while sidekiq_queue_length(queue_from) > 0
          Sidekiq.redis do |conn|
            conn.rpoplpush "queue:#{queue_from}", "queue:#{to}"
          end
        end
      end

      def sidekiq_queue_length(queue_name)
        Sidekiq.redis do |conn|
          conn.llen("queue:#{queue_name}")
        end
      end

      def check_trigger_permissions!(table)
        unless Grant.create_and_execute_trigger?(table)
          dbname = Database.main.database_name
          user = Database.main.username

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

      # Returns the name for a check constraint
      #
      # type:
      # - Any value, as long as it is unique
      # - Constraint names are unique per table in Postgres, and, additionally,
      #   we can have multiple check constraints over a column
      #   So we use the (table, column, type) triplet as a unique name
      # - e.g. we use 'max_length' when adding checks for text limits
      #        or 'not_null' when adding a NOT NULL constraint
      #
      def check_constraint_name(table, column, type)
        identifier = "#{table}_#{column}_check_#{type}"
        # Check concurrent_foreign_key_name() for info on why we use a hash
        hashed_identifier = Digest::SHA256.hexdigest(identifier).first(10)

        "check_#{hashed_identifier}"
      end

      def check_constraint_exists?(table, constraint_name)
        # Constraint names are unique per table in Postgres, not per schema
        # Two tables can have constraints with the same name, so we filter by
        # the table name in addition to using the constraint_name
        check_sql = <<~SQL
          SELECT COUNT(*)
          FROM pg_catalog.pg_constraint con
            INNER JOIN pg_catalog.pg_class rel
              ON rel.oid = con.conrelid
            INNER JOIN pg_catalog.pg_namespace nsp
              ON nsp.oid = con.connamespace
          WHERE con.contype = 'c'
          AND con.conname = #{connection.quote(constraint_name)}
          AND nsp.nspname = #{connection.quote(current_schema)}
          AND rel.relname = #{connection.quote(table)}
        SQL

        connection.select_value(check_sql) > 0
      end

      # Adds a check constraint to a table
      #
      # This method is the generic helper for adding any check constraint
      # More specialized helpers may use it (e.g. add_text_limit or add_not_null)
      #
      # This method only requires minimal locking:
      # - The constraint is added using NOT VALID
      #   This allows us to add the check constraint without validating it
      # - The check will be enforced for new data (inserts) coming in
      # - If `validate: true` the constraint is also validated
      #   Otherwise, validate_check_constraint() can be used at a later stage
      # - Check comments on add_concurrent_foreign_key for more info
      #
      # table  - The table the constraint will be added to
      # check  - The check clause to add
      #          e.g. 'char_length(name) <= 5' or 'store IS NOT NULL'
      # constraint_name - The name of the check constraint (otherwise auto-generated)
      #                   Should be unique per table (not per column)
      # validate - Whether to validate the constraint in this call
      #
      def add_check_constraint(table, check, constraint_name, validate: true)
        validate_check_constraint_name!(constraint_name)

        # Transactions would result in ALTER TABLE locks being held for the
        # duration of the transaction, defeating the purpose of this method.
        if transaction_open?
          raise 'add_check_constraint can not be run inside a transaction'
        end

        if check_constraint_exists?(table, constraint_name)
          warning_message = <<~MESSAGE
            Check constraint was not created because it exists already
            (this may be due to an aborted migration or similar)
            table: #{table}, check: #{check}, constraint name: #{constraint_name}
          MESSAGE

          Gitlab::AppLogger.warn warning_message
        else
          # Only add the constraint without validating it
          # Even though it is fast, ADD CONSTRAINT requires an EXCLUSIVE lock
          # Use with_lock_retries to make sure that this operation
          # will not timeout on tables accessed by many processes
          with_lock_retries do
            execute <<-EOF.strip_heredoc
            ALTER TABLE #{table}
            ADD CONSTRAINT #{constraint_name}
            CHECK ( #{check} )
            NOT VALID;
            EOF
          end
        end

        if validate
          validate_check_constraint(table, constraint_name)
        end
      end

      def validate_check_constraint(table, constraint_name)
        validate_check_constraint_name!(constraint_name)

        unless check_constraint_exists?(table, constraint_name)
          raise missing_schema_object_message(table, "check constraint", constraint_name)
        end

        disable_statement_timeout do
          # VALIDATE CONSTRAINT only requires a SHARE UPDATE EXCLUSIVE LOCK
          # It only conflicts with other validations and creating indexes
          execute("ALTER TABLE #{table} VALIDATE CONSTRAINT #{constraint_name};")
        end
      end

      def remove_check_constraint(table, constraint_name)
        validate_check_constraint_name!(constraint_name)

        # DROP CONSTRAINT requires an EXCLUSIVE lock
        # Use with_lock_retries to make sure that this will not timeout
        with_lock_retries do
          execute <<-EOF.strip_heredoc
          ALTER TABLE #{table}
          DROP CONSTRAINT IF EXISTS #{constraint_name}
          EOF
        end
      end

      # Copies all check constraints for the old column to the new column.
      #
      # table - The table containing the columns.
      # old - The old column.
      # new - The new column.
      # schema - The schema the table is defined for
      #          If it is not provided, then the current_schema is used
      def copy_check_constraints(table, old, new, schema: nil)
        if transaction_open?
          raise 'copy_check_constraints can not be run inside a transaction'
        end

        unless column_exists?(table, old)
          raise "Column #{old} does not exist on #{table}"
        end

        unless column_exists?(table, new)
          raise "Column #{new} does not exist on #{table}"
        end

        table_with_schema = schema.present? ? "#{schema}.#{table}" : table

        check_constraints_for(table, old, schema: schema).each do |check_c|
          validate = !(check_c["constraint_def"].end_with? "NOT VALID")

          # Normalize:
          # - Old constraint definitions:
          #    '(char_length(entity_path) <= 5500)'
          # - Definitionss from pg_get_constraintdef(oid):
          #    'CHECK ((char_length(entity_path) <= 5500))'
          # - Definitions from pg_get_constraintdef(oid, pretty_bool):
          #    'CHECK (char_length(entity_path) <= 5500)'
          # - Not valid constraints: 'CHECK (...) NOT VALID'
          # to a single format that we can use:
          #    '(char_length(entity_path) <= 5500)'
          check_definition = check_c["constraint_def"]
                              .sub(/^\s*(CHECK)?\s*\({0,2}/, '(')
                              .sub(/\){0,2}\s*(NOT VALID)?\s*$/, ')')

          constraint_name = begin
            if check_definition == "(#{old} IS NOT NULL)"
              not_null_constraint_name(table_with_schema, new)
            elsif check_definition.start_with? "(char_length(#{old}) <="
              text_limit_name(table_with_schema, new)
            else
              check_constraint_name(table_with_schema, new, 'copy_check_constraint')
            end
          end

          add_check_constraint(
            table_with_schema,
            check_definition.gsub(old.to_s, new.to_s),
            constraint_name,
            validate: validate
          )
        end
      end

      # Migration Helpers for adding limit to text columns
      def add_text_limit(table, column, limit, constraint_name: nil, validate: true)
        add_check_constraint(
          table,
          "char_length(#{column}) <= #{limit}",
          text_limit_name(table, column, name: constraint_name),
          validate: validate
        )
      end

      def validate_text_limit(table, column, constraint_name: nil)
        validate_check_constraint(table, text_limit_name(table, column, name: constraint_name))
      end

      def remove_text_limit(table, column, constraint_name: nil)
        remove_check_constraint(table, text_limit_name(table, column, name: constraint_name))
      end

      def check_text_limit_exists?(table, column, constraint_name: nil)
        check_constraint_exists?(table, text_limit_name(table, column, name: constraint_name))
      end

      # Migration Helpers for managing not null constraints
      def add_not_null_constraint(table, column, constraint_name: nil, validate: true)
        if column_is_nullable?(table, column)
          add_check_constraint(
            table,
            "#{column} IS NOT NULL",
            not_null_constraint_name(table, column, name: constraint_name),
            validate: validate
          )
        else
          warning_message = <<~MESSAGE
            NOT NULL check constraint was not created:
            column #{table}.#{column} is already defined as `NOT NULL`
          MESSAGE

          Gitlab::AppLogger.warn warning_message
        end
      end

      def validate_not_null_constraint(table, column, constraint_name: nil)
        validate_check_constraint(
          table,
          not_null_constraint_name(table, column, name: constraint_name)
        )
      end

      def remove_not_null_constraint(table, column, constraint_name: nil)
        remove_check_constraint(
          table,
          not_null_constraint_name(table, column, name: constraint_name)
        )
      end

      def check_not_null_constraint_exists?(table, column, constraint_name: nil)
        check_constraint_exists?(
          table,
          not_null_constraint_name(table, column, name: constraint_name)
        )
      end

      def create_extension(extension)
        execute('CREATE EXTENSION IF NOT EXISTS %s' % extension)
      rescue ActiveRecord::StatementInvalid => e
        dbname = Database.main.database_name
        user = Database.main.username

        warn(<<~MSG) if e.to_s =~ /permission denied/
          GitLab requires the PostgreSQL extension '#{extension}' installed in database '#{dbname}', but
          the database user is not allowed to install the extension.

          You can either install the extension manually using a database superuser:

            CREATE EXTENSION IF NOT EXISTS #{extension}

          Or, you can solve this by logging in to the GitLab
          database (#{dbname}) using a superuser and running:

              ALTER #{user} WITH SUPERUSER

          This query will grant the user superuser permissions, ensuring any database extensions
          can be installed through migrations.

          For more information, refer to https://docs.gitlab.com/ee/install/postgresql_extensions.html.
        MSG

        raise
      end

      def drop_extension(extension)
        execute('DROP EXTENSION IF EXISTS %s' % extension)
      rescue ActiveRecord::StatementInvalid => e
        dbname = Database.main.database_name
        user = Database.main.username

        warn(<<~MSG) if e.to_s =~ /permission denied/
          This migration attempts to drop the PostgreSQL extension '#{extension}'
          installed in database '#{dbname}', but the database user is not allowed
          to drop the extension.

          You can either drop the extension manually using a database superuser:

            DROP EXTENSION IF EXISTS #{extension}

          Or, you can solve this by logging in to the GitLab
          database (#{dbname}) using a superuser and running:

              ALTER #{user} WITH SUPERUSER

          This query will grant the user superuser permissions, ensuring any database extensions
          can be dropped through migrations.

          For more information, refer to https://docs.gitlab.com/ee/install/postgresql_extensions.html.
        MSG

        raise
      end

      def rename_constraint(table_name, old_name, new_name)
        execute <<~SQL
          ALTER TABLE #{quote_table_name(table_name)}
          RENAME CONSTRAINT #{quote_column_name(old_name)} TO #{quote_column_name(new_name)}
        SQL
      end

      private

      def validate_check_constraint_name!(constraint_name)
        if constraint_name.to_s.length > MAX_IDENTIFIER_NAME_LENGTH
          raise "The maximum allowed constraint name is #{MAX_IDENTIFIER_NAME_LENGTH} characters"
        end
      end

      # Returns an ActiveRecord::Result containing the check constraints
      # defined for the given column.
      #
      # If the schema is not provided, then the current_schema is used
      def check_constraints_for(table, column, schema: nil)
        check_sql = <<~SQL
          SELECT
            ccu.table_schema as schema_name,
            ccu.table_name as table_name,
            ccu.column_name as column_name,
            con.conname as constraint_name,
            pg_get_constraintdef(con.oid) as constraint_def
          FROM pg_catalog.pg_constraint con
            INNER JOIN pg_catalog.pg_class rel
              ON rel.oid = con.conrelid
            INNER JOIN pg_catalog.pg_namespace nsp
              ON nsp.oid = con.connamespace
            INNER JOIN information_schema.constraint_column_usage ccu
              ON con.conname = ccu.constraint_name
                     AND nsp.nspname = ccu.constraint_schema
                     AND rel.relname = ccu.table_name
          WHERE  nsp.nspname = #{connection.quote(schema.presence || current_schema)}
            AND rel.relname = #{connection.quote(table)}
            AND ccu.column_name = #{connection.quote(column)}
            AND con.contype = 'c'
          ORDER BY constraint_name
        SQL

        connection.exec_query(check_sql)
      end

      def statement_timeout_disabled?
        # This is a string of the form "100ms" or "0" when disabled
        connection.select_value('SHOW statement_timeout') == "0"
      end

      def column_is_nullable?(table, column)
        # Check if table.column has not been defined with NOT NULL
        check_sql = <<~SQL
          SELECT c.is_nullable
          FROM information_schema.columns c
          WHERE c.table_schema = #{connection.quote(current_schema)}
            AND c.table_name = #{connection.quote(table)}
            AND c.column_name = #{connection.quote(column)}
        SQL

        connection.select_value(check_sql) == 'YES'
      end

      def text_limit_name(table, column, name: nil)
        name.presence || check_constraint_name(table, column, 'max_length')
      end

      def not_null_constraint_name(table, column, name: nil)
        name.presence || check_constraint_name(table, column, 'not_null')
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

        update_column_in_batches(table, new, old_value, batch_column_name: batch_column_name)

        add_not_null_constraint(table, new) unless old_col.null

        copy_indexes(table, old, new)
        copy_foreign_keys(table, old, new)
        copy_check_constraints(table, old, new)
      end

      def validate_timestamp_column_name!(column_name)
        return if PERMITTED_TIMESTAMP_COLUMNS.member?(column_name)

        raise <<~MESSAGE
          Illegal timestamp column name! Got #{column_name}.
          Must be one of: #{PERMITTED_TIMESTAMP_COLUMNS.to_a}
        MESSAGE
      end

      def validate_not_in_transaction!(method_name, modifier = nil)
        return unless transaction_open?

        raise <<~ERROR
          #{["`#{method_name}`", modifier].compact.join(' ')} cannot be run inside a transaction.

          You can disable transactions by calling `disable_ddl_transaction!` in the body of
          your migration class
        ERROR
      end
    end
  end
end
