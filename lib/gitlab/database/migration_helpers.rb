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
      def add_concurrent_index(*args)
        if transaction_open?
          raise 'add_concurrent_index can not be run inside a transaction, ' \
            'you can disable transactions by calling disable_ddl_transaction! ' \
            'in the body of your migration class'
        end

        if Database.postgresql?
          args << { algorithm: :concurrently }
        end

        add_index(*args)
      end

      # Updates the value of a column in batches.
      #
      # This method updates the table in batches of 5% of the total row count.
      # Any data inserted while running this method (or after it has finished
      # running) is _not_ updated automatically.
      #
      # This method _only_ updates rows where the column's value is set to NULL.
      #
      # table - The name of the table.
      # column - The name of the column to update.
      # value - The value for the column.
      def update_column_in_batches(table, column, value)
        quoted_table = quote_table_name(table)
        quoted_column = quote_column_name(column)

        ##
        # Workaround for #17711
        #
        # It looks like for MySQL `ActiveRecord::Base.conntection.quote(true)`
        # returns correct value (1), but `ActiveRecord::Migration.new.quote`
        # returns incorrect value ('true'), which causes migrations to fail.
        #
        quoted_value = connection.quote(value)
        processed = 0

        total = exec_query("SELECT COUNT(*) AS count FROM #{quoted_table}").
          to_hash.
          first['count'].
          to_i

        # Update in batches of 5%
        batch_size = ((total / 100.0) * 5.0).ceil

        while processed < total
          start_row = exec_query(%Q{
            SELECT id
            FROM #{quoted_table}
            ORDER BY id ASC
            LIMIT 1 OFFSET #{processed}
          }).to_hash.first

          stop_row = exec_query(%Q{
            SELECT id
            FROM #{quoted_table}
            ORDER BY id ASC
            LIMIT 1 OFFSET #{processed + batch_size}
          }).to_hash.first

          query = %Q{
            UPDATE #{quoted_table}
            SET #{quoted_column} = #{quoted_value}
            WHERE id >= #{start_row['id']}
          }

          if stop_row
            query += " AND id < #{stop_row['id']}"
          end

          execute(query)

          processed += batch_size
        end
      end

      # Adds a column with a default value without locking an entire table.
      #
      # This method runs the following steps:
      #
      # 1. Add the column with a default value of NULL.
      # 2. Update all existing rows in batches.
      # 3. Change the default value of the column to the specified value.
      # 4. Update any remaining rows.
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
      def add_column_with_default(table, column, type, default:, allow_null: false)
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
            update_column_in_batches(table, column, default)
          end
        # We want to rescue _all_ exceptions here, even those that don't inherit
        # from StandardError.
        rescue Exception => error # rubocop: disable all
          remove_column(table, column)

          raise error
        end

        change_column_null(table, column, false) unless allow_null
      end
    end
  end
end
