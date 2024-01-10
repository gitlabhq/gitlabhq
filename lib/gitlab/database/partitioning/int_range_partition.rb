# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class IntRangePartition
        include Comparable

        def self.from_sql(table, partition_name, definition)
          matches = definition.match(/FOR VALUES FROM \('?(?<from>\d+)'?\) TO \('?(?<to>\d+)'?\)/)

          raise ArgumentError, "Unknown partition definition: #{definition}" unless matches

          to = matches[:to].to_i
          from = matches[:from].to_i

          new(table, from, to, partition_name: partition_name)
        end

        attr_reader :table, :from, :to

        def initialize(table, from, to, partition_name: nil)
          @table = table.to_s
          @from = from
          @to = to
          @partition_name = partition_name

          validate!
        end

        def partition_name
          @partition_name || "#{table}_#{from}"
        end

        def to_sql
          from_sql = conn.quote(from)
          to_sql = conn.quote(to)

          <<~SQL
            CREATE TABLE IF NOT EXISTS #{fully_qualified_partition}
            PARTITION OF #{conn.quote_table_name(table)}
            FOR VALUES FROM (#{from_sql}) TO (#{to_sql})
          SQL
        end

        def ==(other)
          table == other.table && partition_name == other.partition_name && from == other.from && to == other.to
        end
        alias_method :eql?, :==

        def hash
          [table, partition_name, from, to].hash
        end

        def <=>(other)
          return if table != other.table

          [from.to_i, to.to_i] <=> [other.from.to_i, other.to.to_i]
        end

        def holds_data?
          conn.execute("SELECT 1 FROM #{fully_qualified_partition} LIMIT 1").ntuples > 0
        end

        private

        def validate!
          raise '`to` statement must be greater than 0' unless to.to_i > 0
          raise '`from` statement must be greater than 0' unless from.to_i > 0
          raise '`to` must be greater than `from`' unless to.to_i > from.to_i
        end

        def fully_qualified_partition
          format("%s.%s", conn.quote_table_name(Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA),
            conn.quote_table_name(partition_name))
        end

        def conn
          @conn ||= Gitlab::Database::SharedModel.connection
        end
      end
    end
  end
end
