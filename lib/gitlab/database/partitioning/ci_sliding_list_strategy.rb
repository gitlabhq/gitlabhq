# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class CiSlidingListStrategy < SlidingListStrategy
        def current_partitions
          Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            MultipleNumericListPartition.from_sql(table_name, partition.name, partition.condition)
          end.sort
        end

        def initial_partition
          partition_for(100)
        end

        def next_partition
          partition_for(active_partition.values.max + 1)
        end

        def missing_partitions
          partitions = []
          partitions << initial_partition if no_partitions_exist?
          partitions << next_partition if next_partition_if.call(active_partition)
          partitions
        end

        def validate_and_fix; end

        def after_adding_partitions; end

        def extra_partitions
          []
        end

        def active_partition
          super || initial_partition
        end

        private

        def ensure_partitioning_column_ignored_or_readonly!; end

        def partition_for(value)
          MultipleNumericListPartition.new(table_name, value, partition_name: partition_name(value))
        end

        def partition_name(value)
          [
            table_name.to_s.delete_prefix('p_'),
            value
          ].join('_')
        end
      end
    end
  end
end
