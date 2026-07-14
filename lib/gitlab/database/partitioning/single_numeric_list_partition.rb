# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class SingleNumericListPartition
        include Comparable

        def self.from_sql(table, partition_name, definition)
          # A list partition can support multiple values, but we only support a single number
          matches = definition.match(/FOR VALUES IN \('?(?<value>\d+)'?\)/)

          raise ArgumentError, 'Unknown partition definition' unless matches

          value = Integer(matches[:value])

          new(table, value, partition_name: partition_name)
        end

        def self.from_export_definition(table, partition_name, definition)
          definition = definition.with_indifferent_access
          values = Array(definition[:values])

          raise ArgumentError, 'Expected a single value' if values.size != 1

          new(table, Integer(values.first), partition_name: partition_name)
        end

        attr_reader :table, :value

        def initialize(table, value, partition_name: nil)
          @table = table
          @value = value
          @partition_name = partition_name
        end

        def partition_name
          @partition_name || "#{table}_#{value}"
        end

        def data_size
          execute("SELECT pg_table_size(#{quote(full_partition_name)})").first['pg_table_size']
        end

        def to_create_sql
          <<~SQL
            CREATE TABLE IF NOT EXISTS #{fully_qualified_partition}
            (LIKE #{conn.quote_table_name(table)} INCLUDING ALL)
          SQL
        end

        def to_attach_sql
          <<~SQL
            ALTER TABLE #{quote_table_name(table)}
            ATTACH PARTITION #{fully_qualified_partition}
            FOR VALUES IN (#{quote(value)})
          SQL
        end

        def to_detach_sql
          <<~SQL
            ALTER TABLE #{quote_table_name(table)}
            DETACH PARTITION #{fully_qualified_partition}
          SQL
        end

        def ==(other)
          table == other.table &&
            partition_name == other.partition_name &&
            value == other.value
        end
        alias_method :eql?, :==

        def hash
          [table, partition_name, value].hash
        end

        def <=>(other)
          return if table != other.table

          value <=> other.value
        end

        def export_definition
          { partition_name: partition_name, values: [value] }
        end

        def covers?(other)
          value == other.value
        end

        private

        delegate :execute, :quote, :quote_table_name, to: :conn, private: true

        def full_partition_name
          "%s.%s" % [Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA, partition_name]
        end

        def fully_qualified_partition
          quote_table_name(full_partition_name)
        end

        def conn
          @conn ||= Gitlab::Database::SharedModel.connection
        end
      end
    end
  end
end
