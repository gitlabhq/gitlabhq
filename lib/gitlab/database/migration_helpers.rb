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
        end

        add_index(table_name, column_name, options)
      end

      # Updates the value of a column in batches.
      #
      # This method updates the table in batches of 5% of the total row count.
      # This method will continue updating rows until no rows remain.
      #
      # When given a block this method will yield to values to the block:
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
      # This would result in this method updating only rows there
      # `projects.some_column` equals "hello".
      #
      # table - The name of the table.
      # column - The name of the column to update.
      # value - The value for the column.
      def update_column_in_batches(table, column, value)
        table = Arel::Table.new(table)
        processed = 0

        count_arel = table.project(Arel.star.count.as('count'))
        count_arel = yield table, count_arel if block_given?

        total = exec_query(count_arel.to_sql).to_hash.first['count'].to_i

        # Update in batches of 5% until we run out of any rows to update.
        batch_size = ((total / 100.0) * 5.0).ceil

        loop do
          start_arel = table.project(table[:id]).
            order(table[:id].asc).
            take(1).
            skip(processed)

          start_arel = yield table, start_arel if block_given?
          start_row = exec_query(start_arel.to_sql).to_hash.first

          # There are no more rows to process
          break unless start_row

          stop_arel = table.project(table[:id]).
            order(table[:id].asc).
            take(1).
            skip(processed + batch_size)

          stop_arel = yield table, stop_arel if block_given?
          stop_row = exec_query(stop_arel.to_sql).to_hash.first

          update_manager = Arel::UpdateManager.new(ActiveRecord::Base)

          update_arel = update_manager.table(table).
            set([[table[column], value]]).
            where(table[:id].gteq(start_row['id']))

          update_arel = yield table, update_arel if block_given?

          if stop_row
            update_arel = update_arel.where(table[:id].lt(stop_row['id']))
          end

          execute(update_arel.to_sql)

          processed += batch_size
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
      # allow_null - When set to `true` the column will allow NULL values, the
      #              default is to not allow NULL values.
      #
      # This method can also take a block which is passed directly to the
      # `update_column_in_batches` method.
      def add_column_with_default(table, column, type, default:, allow_null: false, &block)
        if transaction_open?
          raise 'add_column_with_default can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        transaction do
          add_column(table, column, type, default: nil)

          # Changing the default before the update ensures any newly inserted
          # rows already use the proper default value.
          change_column_default(table, column, default)
        end

        begin
          transaction do
            update_column_in_batches(table, column, default, &block)

            change_column_null(table, column, false) unless allow_null
          end
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
