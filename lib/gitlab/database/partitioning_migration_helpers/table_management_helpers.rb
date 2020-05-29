# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module TableManagementHelpers
        include SchemaHelpers

        # Creates a partitioned copy of an existing table, using a RANGE partitioning strategy on a timestamp column.
        # One partition is created per month between the given `min_date` and `max_date`.
        #
        # A copy of the original table is required as PG currently does not support partitioning existing tables.
        #
        # Example:
        #
        #   partition_table_by_date :audit_events, :created_at, min_date: Date.new(2020, 1), max_date: Date.new(2020, 6)
        #
        # Required options are:
        #   :min_date - a date specifying the lower bounds of the partition range
        #   :max_date - a date specifying the upper bounds of the partitioning range
        #
        def partition_table_by_date(table_name, column_name, min_date:, max_date:)
          raise "max_date #{max_date} must be greater than min_date #{min_date}" if min_date >= max_date

          primary_key = connection.primary_key(table_name)
          raise "primary key not defined for #{table_name}" if primary_key.nil?

          partition_column = find_column_definition(table_name, column_name)
          raise "partition column #{column_name} does not exist on #{table_name}" if partition_column.nil?

          new_table_name = partitioned_table_name(table_name)
          create_range_partitioned_copy(new_table_name, table_name, partition_column, primary_key)
          create_daterange_partitions(new_table_name, partition_column.name, min_date, max_date)
        end

        # Clean up a partitioned copy of an existing table. This deletes the partitioned table and all partitions.
        #
        # Example:
        #
        #   drop_partitioned_table_for :audit_events
        #
        def drop_partitioned_table_for(table_name)
          drop_table(partitioned_table_name(table_name))
        end

        private

        def partitioned_table_name(table)
          tmp_table_name("#{table}_part")
        end

        def find_column_definition(table, column)
          connection.columns(table).find { |c| c.name == column.to_s }
        end

        def create_range_partitioned_copy(table_name, template_table_name, partition_column, primary_key)
          tmp_column_name = object_name(partition_column.name, 'partition_key')

          execute(<<~SQL)
            CREATE TABLE #{table_name} (
              LIKE #{template_table_name} INCLUDING ALL EXCLUDING INDEXES,
              #{tmp_column_name} #{partition_column.sql_type} NOT NULL,
              PRIMARY KEY (#{[primary_key, tmp_column_name].join(", ")})
            ) PARTITION BY RANGE (#{tmp_column_name})
          SQL

          remove_column(table_name, partition_column.name)
          rename_column(table_name, tmp_column_name, partition_column.name)
          change_column_default(table_name, primary_key, nil)
        end

        def create_daterange_partitions(table_name, column_name, min_date, max_date)
          min_date = min_date.beginning_of_month.to_date
          max_date = max_date.next_month.beginning_of_month.to_date

          create_range_partition("#{table_name}_000000", table_name, 'MINVALUE', to_sql_date_literal(min_date))

          while min_date < max_date
            partition_name = "#{table_name}_#{min_date.strftime('%Y%m')}"
            next_date = min_date.next_month
            lower_bound = to_sql_date_literal(min_date)
            upper_bound = to_sql_date_literal(next_date)

            create_range_partition(partition_name, table_name, lower_bound, upper_bound)
            min_date = next_date
          end
        end

        def to_sql_date_literal(date)
          connection.quote(date.strftime('%Y-%m-%d'))
        end

        def create_range_partition(partition_name, table_name, lower_bound, upper_bound)
          execute(<<~SQL)
            CREATE TABLE #{partition_name} PARTITION OF #{table_name}
            FOR VALUES FROM (#{lower_bound}) TO (#{upper_bound})
          SQL
        end
      end
    end
  end
end
