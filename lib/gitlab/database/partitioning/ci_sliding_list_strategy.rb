# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class CiSlidingListStrategy < SlidingListStrategy
        INITIAL_PARTITION = 100
        POSSIBLE_PARTITIONS_PER_EXECUTION = 5

        def current_partitions
          Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            MultipleNumericListPartition.from_sql(table_name, partition.name, partition.condition,
              schema: partition.schema)
          end.sort
        end

        def initial_partition
          partition_for(INITIAL_PARTITION)
        end

        def next_partition
          partition_for(active_partition.values.max + 1)
        end

        def missing_partitions
          desired_partitions - current_partitions
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

        def desired_partitions
          result = next_partitions(active_partition.values.max.next)
            .prepend(active_partition)
            .each_cons(2)
            .with_object([]) { |(prev, current), result| result << current if next_partition_if.call(prev) }
          result.prepend(initial_partition) if no_partitions_exist?
          result
        end

        def next_partitions(value)
          value
            .upto(value + POSSIBLE_PARTITIONS_PER_EXECUTION)
            .map { |value| partition_for(value) }
        end

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
