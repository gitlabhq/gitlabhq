module Gitlab
  module Database
    module MigrationHelpers
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
          return add_foreign_key(source, target,
                                 column: column,
                                 on_delete: on_delete)
        else
          on_delete = 'SET NULL' if on_delete == :nullify
        end

        disable_statement_timeout

        key_name = concurrent_foreign_key_name(source, column)

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

        # Validate the existing constraint. This can potentially take a very
        # long time to complete, but fortunately does not lock the source table
        # while running.
        execute("ALTER TABLE #{source} VALIDATE CONSTRAINT #{key_name};")
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

        trigger_name = rename_trigger_name(table, old, new)
        quoted_table = quote_table_name(table)
        quoted_old = quote_column_name(old)
        quoted_new = quote_column_name(new)

        if Database.postgresql?
          install_rename_triggers_for_postgresql(trigger_name, quoted_table,
                                                 quoted_old, quoted_new)
        else
          install_rename_triggers_for_mysql(trigger_name, quoted_table,
                                            quoted_old, quoted_new)
        end

        update_column_in_batches(table, new, Arel::Table.new(table)[old])

        change_column_null(table, new, false) unless old_col.null

        copy_indexes(table, old, new)
        copy_foreign_keys(table, old, new)
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

        if Database.postgresql?
          remove_rename_triggers_for_postgresql(table, trigger_name)
        else
          remove_rename_triggers_for_mysql(trigger_name)
        end

        remove_column(table, old)
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
        execute("DROP TRIGGER #{trigger} ON #{table}")
        execute("DROP FUNCTION #{trigger}()")
      end

      # Removes the triggers used for renaming a MySQL column concurrently.
      def remove_rename_triggers_for_mysql(trigger)
        execute("DROP TRIGGER #{trigger}_insert")
        execute("DROP TRIGGER #{trigger}_update")
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
    end
  end
end
