# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class CiSlidingListStrategy < SlidingListStrategy
        def initial_partition
          partition_for(100)
        end

        def next_partition
          partition_for(active_partition.value + 1)
        end

        def validate_and_fix; end

        def after_adding_partitions; end

        def extra_partitions
          []
        end

        private

        def ensure_partitioning_column_ignored_or_readonly!; end

        def partition_for(value)
          SingleNumericListPartition.new(table_name, value, partition_name: partition_name(value))
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
