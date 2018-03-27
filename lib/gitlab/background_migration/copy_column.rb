# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # CopyColumn is a simple (reusable) background migration that can be used to
    # update the value of a column based on the value of another column in the
    # same table.
    #
    # For this background migration to work the table that is migrated _has_ to
    # have an `id` column as the primary key.
    class CopyColumn
      # table - The name of the table that contains the columns.
      # copy_from - The column containing the data to copy.
      # copy_to - The column to copy the data to.
      # start_id - The start ID of the range of rows to update.
      # end_id - The end ID of the range of rows to update.
      def perform(table, copy_from, copy_to, start_id, end_id)
        return unless connection.column_exists?(table, copy_to)

        quoted_table = connection.quote_table_name(table)
        quoted_copy_from = connection.quote_column_name(copy_from)
        quoted_copy_to = connection.quote_column_name(copy_to)

        # We're using raw SQL here since this job may be frequently executed. As
        # a result dynamically defining models would lead to many unnecessary
        # schema information queries.
        connection.execute <<-SQL.strip_heredoc
        UPDATE #{quoted_table}
        SET #{quoted_copy_to} = #{quoted_copy_from}
        WHERE id BETWEEN #{start_id} AND #{end_id}
        AND #{quoted_copy_from} IS NOT NULL
        AND #{quoted_copy_to} IS NULL
        SQL
      end

      def connection
        ActiveRecord::Base.connection
      end
    end
  end
end
