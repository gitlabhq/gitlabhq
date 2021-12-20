# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class SlidingListStrategy
        attr_reader :model, :partitioning_key, :next_partition_if, :detach_partition_if

        delegate :table_name, to: :model

        def initialize(model, partitioning_key, next_partition_if:, detach_partition_if:)
          @model = model
          @partitioning_key = partitioning_key
          @next_partition_if = next_partition_if
          @detach_partition_if = detach_partition_if

          ensure_partitioning_column_ignored!
        end

        def current_partitions
          Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            SingleNumericListPartition.from_sql(table_name, partition.name, partition.condition)
          end.sort
        end

        def missing_partitions
          if no_partitions_exist?
            [initial_partition]
          elsif next_partition_if.call(active_partition.value)
            [next_partition]
          else
            []
          end
        end

        def initial_partition
          SingleNumericListPartition.new(table_name, 1)
        end

        def next_partition
          SingleNumericListPartition.new(table_name, active_partition.value + 1)
        end

        def extra_partitions
          possibly_extra = current_partitions[0...-1] # Never consider the most recent partition

          possibly_extra.take_while { |p| detach_partition_if.call(p.value) }
        end

        def after_adding_partitions
          active_value = active_partition.value
          model.connection.change_column_default(model.table_name, partitioning_key, active_value)
        end

        def active_partition
          # The current partitions list is sorted, so the last partition has the highest value
          # This is the only partition that receives inserts.
          current_partitions.last
        end

        def no_partitions_exist?
          current_partitions.empty?
        end

        private

        def ensure_partitioning_column_ignored!
          unless model.ignored_columns.include?(partitioning_key.to_s)
            raise "Add #{partitioning_key} to #{model.name}.ignored_columns to use it with SlidingListStrategy"
          end
        end
      end
    end
  end
end
