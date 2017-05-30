module Gitlab
  module Database
    module MigrationHelpers
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
        ON DELETE #{on_delete} NOT VALID;
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
        table = Arel::Table.new(table)

        count_arel = table.project(Arel.star.count.as('count'))
        count_arel = yield table, count_arel if block_given?

        total = exec_query(count_arel.to_sql).to_hash.first['count'].to_i

        return if total == 0

        # Update in batches of 5% until we run out of any rows to update.
        batch_size = ((total / 100.0) * 5.0).ceil

        start_arel = table.project(table[:id]).order(table[:id].asc).take(1)
        start_arel = yield table, start_arel if block_given?
        start_id = exec_query(start_arel.to_sql).to_hash.first['id'].to_i

        loop do
          stop_arel = table.project(table[:id]).
            where(table[:id].gteq(start_id)).
            order(table[:id].asc).
            take(1).
            skip(batch_size)

          stop_arel = yield table, stop_arel if block_given?
          stop_row = exec_query(stop_arel.to_sql).to_hash.first

          update_arel = Arel::UpdateManager.new(ActiveRecord::Base).
            table(table).
            set([[table[column], value]]).
            where(table[:id].gteq(start_id))

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
    end
  end
end
