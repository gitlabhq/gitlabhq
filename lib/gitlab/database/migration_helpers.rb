# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      BACKGROUND_MIGRATION_BATCH_SIZE = 1000 # Number of rows to process per job
      BACKGROUND_MIGRATION_JOB_BUFFER_SIZE = 1000 # Number of jobs to bulk queue at a time

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
            add_column(table_name, column_name, :datetime_with_timezone, options)
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

        if index_exists?(table_name, column_name, options)
          Rails.logger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}" # rubocop:disable Gitlab/RailsLogger
          return
        end

        disable_statement_timeout do
          add_index(table_name, column_name, options)
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

        unless index_exists?(table_name, column_name, options)
          Rails.logger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}" # rubocop:disable Gitlab/RailsLogger
          return
        end

        disable_statement_timeout do
          remove_index(table_name, options.merge({ column: column_name }))
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

        options = options.merge({ algorithm: :concurrently })

        unless index_exists_by_name?(table_name, index_name)
          Rails.logger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, index_name: #{index_name}" # rubocop:disable Gitlab/RailsLogger
          return
        end

        disable_statement_timeout do
          remove_index(table_name, options.merge({ name: index_name }))
        end
      end

      # Adds a foreign key with only minimal locking on the tables involved.
      #
      # This method only requires minimal locking
      #
      # source - The source table containing the foreign key.
      # target - The target table the key points to.
      # column - The name of the column to create the foreign key on.
      # on_delete - The action to perform when associated data is removed,
      #             defaults to "CASCADE".
      # name - The name of the foreign key.
      #
      # rubocop:disable Gitlab/RailsLogger
      def add_concurrent_foreign_key(source, target, column:, on_delete: :cascade, name: nil, validate: true)
        # Transactions would result in ALTER TABLE locks being held for the
        # duration of the transaction, defeating the purpose of this method.
        if transaction_open?
          raise 'add_concurrent_foreign_key can not be run inside a transaction'
        end

        options = {
          column: column,
          on_delete: on_delete,
          name: name.presence || concurrent_foreign_key_name(source, column)
        }

        if foreign_key_exists?(source, target, options)
          warning_message = "Foreign key not created because it exists already " \
            "(this may be due to an aborted migration or similar): " \
            "source: #{source}, target: #{target}, column: #{options[:column]}, "\
            "name: #{options[:name]}, on_delete: #{options[:on_delete]}"

          Rails.logger.warn warning_message
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
            REFERENCES #{target} (id)
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
      # rubocop:enable Gitlab/RailsLogger

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
      def with_lock_retries(**args, &block)
        merged_args = {
          klass: self.class,
          logger: Gitlab::BackgroundMigration::Logger
        }.merge(args)

        Gitlab::Database::WithLockRetries.new(merged_args).run(&block)
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
      def rename_column_concurrently(table, old, new, type: nil, batch_column_name: :id)
        unless column_exists?(table, batch_column_name)
          raise "Column #{batch_column_name} does not exist on #{table}"
        end

        if transaction_open?
          raise 'rename_column_concurrently can not be run inside a transaction'
        end

        check_trigger_permissions!(table)

        create_column_from(table, old, new, type: type, batch_column_name: batch_column_name)

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

        remove_rename_triggers_for_postgresql(table, trigger_name)

        remove_column(table, new)
      end

      # Installs triggers in a table that keep a new column in sync with an old
      # one.
      #
      # table - The name of the table to install the trigger in.
      # old_column - The name of the old column.
      # new_column - The name of the new column.
      def install_rename_triggers(table, old_column, new_column)
        trigger_name = rename_trigger_name(table, old_column, new_column)
        quoted_table = quote_table_name(table)
        quoted_old = quote_column_name(old_column)
        quoted_new = quote_column_name(new_column)

        install_rename_triggers_for_postgresql(
          trigger_name,
          quoted_table,
          quoted_old,
          quoted_new
        )
      end

      # Changes the type of a column concurrently.
      #
      # table - The table containing the column.
      # column - The name of the column to change.
      # new_type - The new column type.
      def change_column_type_concurrently(table, column, new_type)
        temp_column = "#{column}_for_type_change"

        rename_column_concurrently(table, column, temp_column, type: new_type)
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

        remove_rename_triggers_for_postgresql(table, trigger_name)

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

      def perform_background_migration_inline?
        Rails.env.test? || Rails.env.development?
      end

      # Performs a concurrent column rename when using PostgreSQL.
      def install_rename_triggers_for_postgresql(trigger, table, old, new)
        execute <<-EOF.strip_heredoc
        CREATE OR REPLACE FUNCTION #{trigger}()
        RETURNS trigger AS
        $BODY$
        BEGIN
          NEW.#{new} := NEW.#{old};
          RETURN NEW;
        END;
        $BODY$
        LANGUAGE 'plpgsql'
        VOLATILE
        EOF

        execute <<-EOF.strip_heredoc
        DROP TRIGGER IF EXISTS #{trigger}
        ON #{table}
        EOF

        execute <<-EOF.strip_heredoc
        CREATE TRIGGER #{trigger}
        BEFORE INSERT OR UPDATE
        ON #{table}
        FOR EACH ROW
        EXECUTE PROCEDURE #{trigger}()
        EOF
      end

      # Removes the triggers used for renaming a PostgreSQL column concurrently.
      def remove_rename_triggers_for_postgresql(table, trigger)
        execute("DROP TRIGGER IF EXISTS #{trigger} ON #{table}")
        execute("DROP FUNCTION IF EXISTS #{trigger}()")
      end

      # Returns the (base) name to use for triggers when renaming columns.
      def rename_trigger_name(table, old, new)
        'trigger_' + Digest::SHA256.hexdigest("#{table}_#{old}_#{new}").first(12)
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

            options[:opclasses] = opclasses
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

      def remove_foreign_key_if_exists(*args)
        if foreign_key_exists?(*args)
          remove_foreign_key(*args)
        end
      end

      def remove_foreign_key_without_error(*args)
        remove_foreign_key(*args)
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
          dbname = Database.database_name
          user = Database.username

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

      # Bulk queues background migration jobs for an entire table, batched by ID range.
      # "Bulk" meaning many jobs will be pushed at a time for efficiency.
      # If you need a delay interval per job, then use `queue_background_migration_jobs_by_range_at_intervals`.
      #
      # model_class - The table being iterated over
      # job_class_name - The background migration job class as a string
      # batch_size - The maximum number of rows per job
      #
      # Example:
      #
      #     class Route < ActiveRecord::Base
      #       include EachBatch
      #       self.table_name = 'routes'
      #     end
      #
      #     bulk_queue_background_migration_jobs_by_range(Route, 'ProcessRoutes')
      #
      # Where the model_class includes EachBatch, and the background migration exists:
      #
      #     class Gitlab::BackgroundMigration::ProcessRoutes
      #       def perform(start_id, end_id)
      #         # do something
      #       end
      #     end
      def bulk_queue_background_migration_jobs_by_range(model_class, job_class_name, batch_size: BACKGROUND_MIGRATION_BATCH_SIZE)
        raise "#{model_class} does not have an ID to use for batch ranges" unless model_class.column_names.include?('id')

        jobs = []
        table_name = model_class.quoted_table_name

        model_class.each_batch(of: batch_size) do |relation|
          start_id, end_id = relation.pluck("MIN(#{table_name}.id)", "MAX(#{table_name}.id)").first

          if jobs.length >= BACKGROUND_MIGRATION_JOB_BUFFER_SIZE
            # Note: This code path generally only helps with many millions of rows
            # We push multiple jobs at a time to reduce the time spent in
            # Sidekiq/Redis operations. We're using this buffer based approach so we
            # don't need to run additional queries for every range.
            bulk_migrate_async(jobs)
            jobs.clear
          end

          jobs << [job_class_name, [start_id, end_id]]
        end

        bulk_migrate_async(jobs) unless jobs.empty?
      end

      # Queues background migration jobs for an entire table, batched by ID range.
      # Each job is scheduled with a `delay_interval` in between.
      # If you use a small interval, then some jobs may run at the same time.
      #
      # model_class - The table or relation being iterated over
      # job_class_name - The background migration job class as a string
      # delay_interval - The duration between each job's scheduled time (must respond to `to_f`)
      # batch_size - The maximum number of rows per job
      # other_arguments - Other arguments to send to the job
      #
      # *Returns the final migration delay*
      #
      # Example:
      #
      #     class Route < ActiveRecord::Base
      #       include EachBatch
      #       self.table_name = 'routes'
      #     end
      #
      #     queue_background_migration_jobs_by_range_at_intervals(Route, 'ProcessRoutes', 1.minute)
      #
      # Where the model_class includes EachBatch, and the background migration exists:
      #
      #     class Gitlab::BackgroundMigration::ProcessRoutes
      #       def perform(start_id, end_id)
      #         # do something
      #       end
      #     end
      def queue_background_migration_jobs_by_range_at_intervals(model_class, job_class_name, delay_interval, batch_size: BACKGROUND_MIGRATION_BATCH_SIZE, other_job_arguments: [], initial_delay: 0)
        raise "#{model_class} does not have an ID to use for batch ranges" unless model_class.column_names.include?('id')

        # To not overload the worker too much we enforce a minimum interval both
        # when scheduling and performing jobs.
        if delay_interval < BackgroundMigrationWorker.minimum_interval
          delay_interval = BackgroundMigrationWorker.minimum_interval
        end

        final_delay = 0

        model_class.each_batch(of: batch_size) do |relation, index|
          start_id, end_id = relation.pluck(Arel.sql('MIN(id), MAX(id)')).first

          # `BackgroundMigrationWorker.bulk_perform_in` schedules all jobs for
          # the same time, which is not helpful in most cases where we wish to
          # spread the work over time.
          final_delay = initial_delay + delay_interval * index
          migrate_in(final_delay, job_class_name, [start_id, end_id] + other_job_arguments)
        end

        final_delay
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
          FROM pg_index
          JOIN pg_class i ON (indexrelid=i.oid)
          JOIN pg_class t ON (indrelid=t.oid)
          WHERE i.relname = '#{name}' AND t.relname = '#{table}'
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

      def migrate_async(*args)
        with_migration_context do
          BackgroundMigrationWorker.perform_async(*args)
        end
      end

      def migrate_in(*args)
        with_migration_context do
          BackgroundMigrationWorker.perform_in(*args)
        end
      end

      def bulk_migrate_in(*args)
        with_migration_context do
          BackgroundMigrationWorker.bulk_perform_in(*args)
        end
      end

      def bulk_migrate_async(*args)
        with_migration_context do
          BackgroundMigrationWorker.bulk_perform_async(*args)
        end
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
          FROM pg_constraint
          JOIN pg_class ON pg_constraint.conrelid = pg_class.oid
          WHERE pg_constraint.contype = 'c'
          AND pg_constraint.conname = '#{constraint_name}'
          AND pg_class.relname = '#{table}'
        SQL

        connection.select_value(check_sql).positive?
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
      # rubocop:disable Gitlab/RailsLogger
      def add_check_constraint(table, check, constraint_name, validate: true)
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

          Rails.logger.warn warning_message
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
        # DROP CONSTRAINT requires an EXCLUSIVE lock
        # Use with_lock_retries to make sure that this will not timeout
        with_lock_retries do
          execute <<-EOF.strip_heredoc
          ALTER TABLE #{table}
          DROP CONSTRAINT IF EXISTS #{constraint_name}
          EOF
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

          Rails.logger.warn warning_message
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

      private

      def statement_timeout_disabled?
        # This is a string of the form "100ms" or "0" when disabled
        connection.select_value('SHOW statement_timeout') == "0"
      end

      def column_is_nullable?(table, column)
        # Check if table.column has not been defined with NOT NULL
        check_sql = <<~SQL
          SELECT c.is_nullable
          FROM information_schema.columns c
          WHERE c.table_name = '#{table}'
          AND c.column_name = '#{column}'
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

      def create_column_from(table, old, new, type: nil, batch_column_name: :id)
        old_col = column_for(table, old)
        new_type = type || old_col.type

        add_column(table, new, new_type,
                   limit: old_col.limit,
                   precision: old_col.precision,
                   scale: old_col.scale)

        # We set the default value _after_ adding the column so we don't end up
        # updating any existing data with the default value. This isn't
        # necessary since we copy over old values further down.
        change_column_default(table, new, old_col.default) unless old_col.default.nil?

        update_column_in_batches(table, new, Arel::Table.new(table)[old], batch_column_name: batch_column_name)

        add_not_null_constraint(table, new) unless old_col.null

        copy_indexes(table, old, new)
        copy_foreign_keys(table, old, new)
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

      def with_migration_context(&block)
        Gitlab::ApplicationContext.with_context(caller_id: self.class.to_s, &block)
      end
    end
  end
end
