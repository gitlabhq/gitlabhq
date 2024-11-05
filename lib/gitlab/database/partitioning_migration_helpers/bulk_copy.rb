# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      # Helper class to copy data between two tables via upserts
      class BulkCopy
        DELIMITER = ', '

        attr_reader :source_table, :destination_table, :source_column, :connection

        def initialize(source_table, destination_table, source_column, connection:)
          @source_table = source_table
          @destination_table = destination_table
          @source_column = source_column
          @connection = connection
        end

        def copy_between(start_id, stop_id)
          connection.execute(<<~SQL)
            INSERT INTO #{destination_table} (#{column_listing})
            SELECT #{column_listing}
            FROM #{source_table}
            WHERE #{source_column} BETWEEN #{start_id} AND #{stop_id}
            FOR UPDATE
            ON CONFLICT (#{conflict_targets}) DO NOTHING
          SQL
        end

        def copy_relation(relation)
          connection.execute(<<~SQL)
            INSERT INTO #{destination_table} (#{column_listing})
            #{relation.select(column_listing).to_sql}
            FOR UPDATE
            ON CONFLICT (#{conflict_targets}) DO NOTHING
          SQL
        end

        private

        def column_listing
          @column_listing ||= connection.columns(source_table).map(&:name).join(DELIMITER)
        end

        def conflict_targets
          connection.primary_keys(destination_table).join(DELIMITER)
        end
      end
    end
  end
end
