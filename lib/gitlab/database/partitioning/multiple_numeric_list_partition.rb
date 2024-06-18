# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class MultipleNumericListPartition
        include Comparable

        def self.from_sql(table, partition_name, definition, schema:)
          matches = definition.match(/\AFOR VALUES IN \((?<values>.*)\)\z/)

          raise ArgumentError, 'Unknown partition definition' unless matches

          values = matches[:values].scan(/\d+/).map { |value| Integer(value) }

          new(table, values, partition_name: partition_name, schema: schema)
        end

        attr_reader :table, :values

        def initialize(table, values, partition_name: nil, schema: nil)
          @table = table
          @values = Array.wrap(values)
          @partition_name = partition_name
          @schema = schema || Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA
        end

        def partition_name
          @partition_name || ([table] + values).join('_')
        end

        def data_size
          execute("SELECT pg_table_size(#{quote(full_partition_name)})").first['pg_table_size']
        end

        def to_sql
          <<~SQL.squish
            CREATE TABLE IF NOT EXISTS #{fully_qualified_partition}
            PARTITION OF #{quote_table_name(table)}
            FOR VALUES IN (#{quoted_values})
          SQL
        end

        def to_detach_sql
          <<~SQL.squish
            ALTER TABLE #{quote_table_name(table)}
            DETACH PARTITION #{fully_qualified_partition}
          SQL
        end

        def ==(other)
          table == other.table &&
            partition_name == other.partition_name &&
            values == other.values
        end
        alias_method :eql?, :==

        def hash
          [table, partition_name, values].hash
        end

        def <=>(other)
          return if table != other.table

          values <=> other.values
        end

        def before?(partition_id)
          partition_id > values.max
        end

        private

        delegate :execute, :quote, :quote_table_name, to: :conn, private: true

        def full_partition_name
          format("%s.%s", @schema, partition_name)
        end

        def fully_qualified_partition
          quote_table_name(full_partition_name)
        end

        def quoted_values
          values.map { |value| quote(value) }.join(', ')
        end

        def conn
          @conn ||= Gitlab::Database::SharedModel.connection
        end
      end
    end
  end
end
