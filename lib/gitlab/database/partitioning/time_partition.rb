# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class TimePartition
        include Comparable

        def self.from_sql(table, partition_name, definition)
          matches = definition.match(/FOR VALUES FROM \('?(?<from>.+)'?\) TO \('?(?<to>.+)'?\)/)

          raise ArgumentError, "Unknown partition definition: #{definition}" unless matches

          raise NotImplementedError, "Open-end time partitions with MAXVALUE are not supported yet" if matches[:to] == 'MAXVALUE'

          from = matches[:from] == 'MINVALUE' ? nil : matches[:from]
          to = matches[:to]

          new(table, from, to, partition_name: partition_name)
        end

        attr_reader :table, :from, :to

        def initialize(table, from, to, partition_name: nil)
          @table = table.to_s
          @from = date_or_nil(from)
          @to = date_or_nil(to)
          @partition_name = partition_name
        end

        def partition_name
          return @partition_name if @partition_name

          suffix = from&.strftime('%Y%m') || '000000'

          "#{table}_#{suffix}"
        end

        def to_sql
          from_sql = from ? conn.quote(from.strftime('%Y-%m-%d')) : 'MINVALUE'
          to_sql = conn.quote(to.strftime('%Y-%m-%d'))

          <<~SQL
            CREATE TABLE IF NOT EXISTS #{fully_qualified_partition}
            PARTITION OF #{conn.quote_table_name(table)}
            FOR VALUES FROM (#{from_sql}) TO (#{to_sql})
          SQL
        end

        def to_detach_sql
          <<~SQL
            ALTER TABLE #{conn.quote_table_name(table)}
            DETACH PARTITION #{fully_qualified_partition}
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

          partition_name <=> other.partition_name
        end

        private

        def date_or_nil(obj)
          return unless obj
          return obj if obj.is_a?(Date)

          Date.parse(obj)
        end

        def fully_qualified_partition
          "%s.%s" % [conn.quote_table_name(Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA), conn.quote_table_name(partition_name)]
        end

        def conn
          @conn ||= ActiveRecord::Base.connection
        end
      end
    end
  end
end
