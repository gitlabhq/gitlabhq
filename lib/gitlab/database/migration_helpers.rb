module Gitlab
  module Database
    module MigrationHelpers
      BACKGROUND_MIGRATION_BATCH_SIZE = 1000 # Number of rows to process per job
      BACKGROUND_MIGRATION_JOB_BUFFER_SIZE = 1000 # Number of jobs to bulk queue at a time

      # Adds `created_at` and `updated_at` columns with timezone information.
      #
      # This method is an improved version of Rails' built-in method `add_timestamps`.
      #
      # Available options are:
      # default - The default value for the column.
      # null - When set to `true` the column will allow NULL values.
      #        The default is to not allow NULL values.
      def add_timestamps_with_timezone(table_name, options = {})
        options[:null] = false if options[:null].nil?

        [:created_at, :updated_at].each do |column_name|
          if options[:default] && transaction_open?
            raise '`add_timestamps_with_timezone` with default value cannot be run inside a transaction. ' \
              'You can disable transactions by calling `disable_ddl_transaction!` ' \
              'in the body of your migration class'
          end

          # If default value is presented, use `add_column_with_default` method instead.
          if options[:default]
            add_column_with_default(
              table_name,
              column_name,
              :datetime_with_timezone,
              default: options[:default],
              allow_null: options[:null]
            )
          else
            add_column(table_name, column_name, :datetime_with_timezone, options)
          end
        end
      end

      # Creates a new index, concurrently when supported
      #
      # On PostgreSQL this method creates an index concurrently, on MySQL this
      # creates a regular index.
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

        if Database.postgresql?
          options = options.merge({ algorithm: :concurrently })
          disable_statement_timeout
        end

        if index_exists?(table_name, column_name, options)
          Rails.logger.warn "Index not created because it already exists (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
          return
        end

        add_index(table_name, column_name, options)
      end

      # Removes an existed index, concurrently when supported
      #
      # On PostgreSQL this method removes an index concurrently.
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

        if supports_drop_index_concurrently?
          options = options.merge({ algorithm: :concurrently })
          disable_statement_timeout
        end

        unless index_exists?(table_name, column_name, options)
          Rails.logger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, column_name: #{column_name}"
          return
        end

        remove_index(table_name, options.merge({ column: column_name }))
      end

      # Removes an existing index, concurrently when supported
      #
      # On PostgreSQL this method removes an index concurrently.
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

        if supports_drop_index_concurrently?
          options = options.merge({ algorithm: :concurrently })
          disable_statement_timeout
        end

        unless index_exists_by_name?(table_name, index_name)
          Rails.logger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, index_name: #{index_name}"
          return
        end

        remove_index(table_name, options.merge({ name: index_name }))
      end

      # Only available on Postgresql >= 9.2
      def supports_drop_index_concurrently?
        return false unless Database.postgresql?

        version = select_one("SELECT current_setting('server_version_num') AS v")['v'].to_i

        version >= 90200
      end

      # Adds a foreign key with only minimal locking on the tables involved.
      #
      # This method only requires minimal locking when using PostgreSQL. When
      # using MySQL this method will use Rails' default `add_foreign_key`.
      #
      # source - The source table containing the foreign key.
      # target - The target table the key points to.
      # column - The name of the column to create the foreign key on.
      # on_delete - The action to perform when associated data is removed,
      #             defaults to "CASCADE".
      def add_concurrent_foreign_key(source, target, column:, on_delete: :cascade)
        # Transactions would result in ALTER TABLE locks being held for the
        # duration of the transaction, defeating the purpose of this method.
        if transaction_open?
          raise 'add_concurrent_foreign_key can not be run inside a transaction'
        end

        # While MySQL does allow disabling of foreign keys it has no equivalent
        # of PostgreSQL's "VALIDATE CONSTRAINT". As a result we'll just fall
        # back to the normal foreign key procedure.
        if Database.mysql?
          if foreign_key_exists?(source, target, column: column)
            Rails.logger.warn "Foreign key not created because it exists already " \
              "(this may be due to an aborted migration or similar): " \
              "source: #{source}, target: #{target}, column: #{column}"
            return
          end

          return add_foreign_key(source, target,
                                 column: column,
                                 on_delete: on_delete)
        else
          on_delete = 'SET NULL' if on_delete == :nullify
        end

        disable_statement_timeout

        key_name = concurrent_foreign_key_name(source, column)

        unless foreign_key_exists?(source, target, column: column)
          Rails.logger.warn "Foreign key not created because it exists already " \
            "(this may be due to an aborted migration or similar): " \
            "source: #{source}, target: #{target}, column: #{column}"

          # Using NOT VALID allows us to create a key without immediately
          # validating it. This means we keep the ALTER TABLE lock only for a
          # short period of time. The key _is_ enforced for any newly created
          # data.
          execute <<-EOF.strip_heredoc
          ALTER TABLE #{source}
          ADD CONSTRAINT #{key_name}
          FOREIGN KEY (#{column})
          REFERENCES #{target} (id)
          #{on_delete ? "ON DELETE #{on_delete.upcase}" : ''}
          NOT VALID;
          EOF
        end

        # Validate the existing constraint. This can potentially take a very
        # long time to complete, but fortunately does not lock the source table
        # while running.
        #
        # Note this is a no-op in case the constraint is VALID already
        execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{key_name};")
      end

      def foreign_key_exists?(source, target = nil, column: nil)
        foreign_keys(source).any? do |key|
          if column
            key.options[:column].to_s == column.to_s
          else
            key.to_table.to_s == target.to_s
          end
        end
      end

      # Returns the name for a concurrent foreign key.
      #
      # PostgreSQL constraint names have a limit of 63 bytes. The logic used
      # here is based on Rails' foreign_key_name() method, which unfortunately
      # is private so we can't rely on it directly.
      def concurrent_foreign_key_name(table, column)
        "fk_#{Digest::SHA256.hexdigest("#{table}_#{column}_fk").first(10)}"
      end

      # Long-running migrations may take more than the timeout allowed by
      # the database. Disable the session's statement timeout to ensure
      # migrations don't get killed prematurely. (PostgreSQL only)
      def disable_statement_timeout
        execute('SET statement_timeout TO 0') if Database.postgresql?
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
      # rubocop: disable Metrics/AbcSize
      def update_column_in_batches(table, column, value)
        if transaction_open?
          raise 'update_column_in_batches can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        table = Arel::Table.new(table)

        count_arel = table.project(Arel.star.count.as('count'))
        count_arel = yield table, count_arel if block_given?

        total = exec_query(count_arel.to_sql).to_hash.first['count'].to_i

        return if total == 0

        # Update in batches of 5% until we run out of any rows to update.
        batch_size = ((total / 100.0) * 5.0).ceil
        max_size = 1000

        # The upper limit is 1000 to ensure we don't lock too many rows. For
        # example, for "merge_requests" even 1% of the table is around 35 000
        # rows for GitLab.com.
        batch_size = max_size if batch_size > max_size

        start_arel = table.project(table[:id]).order(table[:id].asc).take(1)
        start_arel = yield table, start_arel if block_given?
        start_id = exec_query(start_arel.to_sql).to_hash.first['id'].to_i

        loop do
          stop_arel = table.project(table[:id])
            .where(table[:id].gteq(start_id))
            .order(table[:id].asc)
            .take(1)
            .skip(batch_size)

          stop_arel = yield table, stop_arel if block_given?
          stop_row = exec_query(stop_arel.to_sql).to_hash.first

          update_arel = Arel::UpdateManager.new(ActiveRecord::Base)
            .table(table)
            .set([[table[column], value]])
            .where(table[:id].gteq(start_id))

          if stop_row
            stop_id = stop_row['id'].to_i
            start_id = stop_id
            update_arel = update_arel.where(table[:id].lt(stop_id))
          end

          update_arel = yield table, update_arel if block_given?

          execute(update_arel.to_sql)

          # There are no more rows left to update.
          break unless stop_row
        end
      end

      # Adds a column with a default value without locking an entire table.
      #
      # This method runs the following steps:
      #
      # 1. Add the column with a default value of NULL.
      # 2. Change the default value of the column to the specified value.
      # 3. Update all existing rows in batches.
      # 4. Set a `NOT NULL` constraint on the column if desired (the default).
      #
      # These steps ensure a column can be added to a large and commonly used
      # table without locking the entire table for the duration of the table
      # modification.
      #
      # table - The name of the table to update.
      # column - The name of the column to add.
      # type - The column type (e.g. `:integer`).
      # default - The default value for the column.
      # limit - Sets a column limit. For example, for :integer, the default is
      #         4-bytes. Set `limit: 8` to allow 8-byte integers.
      # allow_null - When set to `true` the column will allow NULL values, the
      #              default is to not allow NULL values.
      #
      # This method can also take a block which is passed directly to the
      # `update_column_in_batches` method.
      def add_column_with_default(table, column, type, default:, limit: nil, allow_null: false, &block)
        if transaction_open?
          raise 'add_column_with_default can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        disable_statement_timeout

        transaction do
          if limit
            add_column(table, column, type, default: nil, limit: limit)
          else
            add_column(table, column, type, default: nil)
          end

          # Changing the default before the update ensures any newly inserted
          # rows already use the proper default value.
          change_column_default(table, column, default)
        end

        begin
          update_column_in_batches(table, column, default, &block)

          change_column_null(table, column, false) unless allow_null
        # We want to rescue _all_ exceptions here, even those that don't inherit
        # from StandardError.
        rescue Exception => error # rubocop: disable all
          remove_column(table, column)

          raise error
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
      def rename_column_concurrently(table, old, new, type: nil)
        if transaction_open?
          raise 'rename_column_concurrently can not be run inside a transaction'
        end

        check_trigger_permissions!(table)

        old_col = column_for(table, old)
        new_type = type || old_col.type

        add_column(table, new, new_type,
                   limit: old_col.limit,
                   precision: old_col.precision,
                   scale: old_col.scale)

        # We set the default value _after_ adding the column so we don't end up
        # updating any existing data with the default value. This isn't
        # necessary since we copy over old values further down.
        change_column_default(table, new, old_col.default) if old_col.default

        install_rename_triggers(table, old, new)

        update_column_in_batches(table, new, Arel::Table.new(table)[old])

        change_column_null(table, new, false) unless old_col.null

        copy_indexes(table, old, new)
        copy_foreign_keys(table, old, new)
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

        if Database.postgresql?
          install_rename_triggers_for_postgresql(trigger_name, quoted_table,
                                                 quoted_old, quoted_new)
        else
          install_rename_triggers_for_mysql(trigger_name, quoted_table,
                                            quoted_old, quoted_new)
        end
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

        if Database.postgresql?
          remove_rename_triggers_for_postgresql(table, trigger_name)
        else
          remove_rename_triggers_for_mysql(trigger_name)
        end

        remove_column(table, old)
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

          BackgroundMigrationWorker.perform_in(
            index * interval,
            'CopyColumn',
            [table, column, temp_column, start_id, end_id]
          )
        end

        # Schedule the renaming of the column to happen (initially) 1 hour after
        # the last batch finished.
        BackgroundMigrationWorker.perform_in(
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
        CREATE TRIGGER #{trigger}
        BEFORE INSERT OR UPDATE
        ON #{table}
        FOR EACH ROW
        EXECUTE PROCEDURE #{trigger}()
        EOF
      end

      # Installs the triggers necessary to perform a concurrent column rename on
      # MySQL.
      def install_rename_triggers_for_mysql(trigger, table, old, new)
        execute <<-EOF.strip_heredoc
        CREATE TRIGGER #{trigger}_insert
        BEFORE INSERT
        ON #{table}
        FOR EACH ROW
        SET NEW.#{new} = NEW.#{old}
        EOF

        execute <<-EOF.strip_heredoc
        CREATE TRIGGER #{trigger}_update
        BEFORE UPDATE
        ON #{table}
        FOR EACH ROW
        SET NEW.#{new} = NEW.#{old}
        EOF
      end

      # Removes the triggers used for renaming a PostgreSQL column concurrently.
      def remove_rename_triggers_for_postgresql(table, trigger)
        execute("DROP TRIGGER IF EXISTS #{trigger} ON #{table}")
        execute("DROP FUNCTION IF EXISTS #{trigger}()")
      end

      # Removes the triggers used for renaming a MySQL column concurrently.
      def remove_rename_triggers_for_mysql(trigger)
        execute("DROP TRIGGER IF EXISTS #{trigger}_insert")
        execute("DROP TRIGGER IF EXISTS #{trigger}_update")
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

          # These options are not supported by MySQL, so we only add them if
          # they were previously set.
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

        columns(table).find { |column| column.name == name }
      end

      # This will replace the first occurance of a string in a column with
      # the replacement
      # On postgresql we can use `regexp_replace` for that.
      # On mysql we find the location of the pattern, and overwrite it
      # with the replacement
      def replace_sql(column, pattern, replacement)
        quoted_pattern = Arel::Nodes::Quoted.new(pattern.to_s)
        quoted_replacement = Arel::Nodes::Quoted.new(replacement.to_s)

        if Database.mysql?
          locate = Arel::Nodes::NamedFunction
            .new('locate', [quoted_pattern, column])
          insert_in_place = Arel::Nodes::NamedFunction
            .new('insert', [column, locate, pattern.size, quoted_replacement])

          Arel::Nodes::SqlLiteral.new(insert_in_place.to_sql)
        else
          replace = Arel::Nodes::NamedFunction
            .new("regexp_replace", [column, quoted_pattern, quoted_replacement])
          Arel::Nodes::SqlLiteral.new(replace.to_sql)
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

For MySQL you instead need to run:

    GRANT ALL PRIVILEGES ON *.* TO #{user}@'%'

Both queries will grant the user super user permissions, ensuring you don't run
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

        model_class.each_batch(of: batch_size) do |relation|
          start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

          if jobs.length >= BACKGROUND_MIGRATION_JOB_BUFFER_SIZE
            # Note: This code path generally only helps with many millions of rows
            # We push multiple jobs at a time to reduce the time spent in
            # Sidekiq/Redis operations. We're using this buffer based approach so we
            # don't need to run additional queries for every range.
            BackgroundMigrationWorker.bulk_perform_async(jobs)
            jobs.clear
          end

          jobs << [job_class_name, [start_id, end_id]]
        end

        BackgroundMigrationWorker.bulk_perform_async(jobs) unless jobs.empty?
      end

      # Queues background migration jobs for an entire table, batched by ID range.
      # Each job is scheduled with a `delay_interval` in between.
      # If you use a small interval, then some jobs may run at the same time.
      #
      # model_class - The table being iterated over
      # job_class_name - The background migration job class as a string
      # delay_interval - The duration between each job's scheduled time (must respond to `to_f`)
      # batch_size - The maximum number of rows per job
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
      def queue_background_migration_jobs_by_range_at_intervals(model_class, job_class_name, delay_interval, batch_size: BACKGROUND_MIGRATION_BATCH_SIZE)
        raise "#{model_class} does not have an ID to use for batch ranges" unless model_class.column_names.include?('id')

        # To not overload the worker too much we enforce a minimum interval both
        # when scheduling and performing jobs.
        if delay_interval < BackgroundMigrationWorker::MIN_INTERVAL
          delay_interval = BackgroundMigrationWorker::MIN_INTERVAL
        end

        model_class.each_batch(of: batch_size) do |relation, index|
          start_id, end_id = relation.pluck('MIN(id), MAX(id)').first

          # `BackgroundMigrationWorker.bulk_perform_in` schedules all jobs for
          # the same time, which is not helpful in most cases where we wish to
          # spread the work over time.
          BackgroundMigrationWorker.perform_in(delay_interval * index, job_class_name, [start_id, end_id])
        end
      end

      # Fetches indexes on a column by name for postgres.
      #
      # This will include indexes using an expression on the column, for example:
      # `CREATE INDEX CONCURRENTLY index_name ON table (LOWER(column));`
      #
      # For mysql, it falls back to the default ActiveRecord implementation that
      # will not find custom indexes. But it will select by name without passing
      # a column.
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
        elsif Gitlab::Database.postgresql?
          postgres_exists_by_name?(table, index)
        else
          false
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
    end
  end
end
