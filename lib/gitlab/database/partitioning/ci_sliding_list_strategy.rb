# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class CiSlidingListStrategy < SlidingListStrategy
        def initial_partition
          partition_name = [table_name.to_s.delete_prefix('p_'), 100].join('_')

          SingleNumericListPartition.new(table_name, 100, partition_name: partition_name)
        end

        def validate_and_fix; end

        def after_adding_partitions; end

        def extra_partitions
          []
        end

        private

        def ensure_partitioning_column_ignored_or_readonly!; end
      end
    end
  end
end
