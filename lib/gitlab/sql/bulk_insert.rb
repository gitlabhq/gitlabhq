module Gitlab
  module SQL
    # Class for building SQL bulk inserts
    class BulkInsert
      def initialize(columns, values_array, table)
        @columns = columns
        @values_array = values_array
        @table = table
      end

      def execute
        ActiveRecord::Base.connection.execute(
          <<-SQL.strip_heredoc
          INSERT INTO #{@table} (#{@columns.join(', ')})
          VALUES #{@values_array.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
        SQL
        )
      end
    end
  end
end
