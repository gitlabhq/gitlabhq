# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class IntRangeStrategy < BaseStrategy
        include Gitlab::Utils::StrongMemoize

        attr_reader :model, :partitioning_key, :partition_size, :analyze_interval

        # We create this many partitions in the future
        HEADROOM = 6
        MIN_ID = 1

        delegate :table_name, to: :model

        def initialize(model, partitioning_key, partition_size:, analyze_interval: nil, sequence_name: nil)
          @model = model
          @partitioning_key = partitioning_key
          @partition_size = partition_size
          @analyze_interval = analyze_interval
          @sequence_name = sequence_name
        end

        def sequence_name
          @sequence_name || model.sequence_name
        end

        def current_partitions
          ensure_connection_set

          int_range_partitions = Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            IntRangePartition.from_sql(table_name, partition.name, partition.condition)
          end

          int_range_partitions.sort
        end

        # Check the currently existing partitions and determine which ones are missing
        def missing_partitions
          ensure_connection_set

          desired_partitions - current_partitions
        end

        def extra_partitions
          ensure_connection_set

          []
        end

        def after_adding_partitions
          ensure_connection_set

          # No-op, required by the partition manager
        end

        def validate_and_fix
          ensure_connection_set

          # No-op, required by the partition manager
        end

        private

        def are_last_partitions_empty?(number_of_partitions)
          partitions = current_partitions.last(number_of_partitions)

          partitions.none?(&:holds_data?)
        end

        def desired_partitions
          end_id = are_partitions_syncronized? ? max_id : max_id + (HEADROOM * partition_size) # Adds 6 new partitions

          create_int_range_partitions(min_id, end_id)
        end

        def create_int_range_partitions(start_id, end_id)
          partitions = []

          while start_id < end_id
            partitions << partition_for(lower_bound: start_id, upper_bound: start_id + partition_size,
              partition_name: partition_name(start_id))

            start_id += partition_size
          end

          partitions
        end

        def min_id
          return MIN_ID unless sequence_name

          seq_name = sequence_name.split('.').last

          model.connection
            .select_value(
              "SELECT min_value FROM pg_sequences WHERE sequencename = $1", :select_seq_start, [seq_name]
            ) || MIN_ID
        end
        strong_memoize_attr :min_id

        def max_id
          last_partition&.to || min_id
        end

        def are_partitions_syncronized?
          last_partition && current_partitions.size >= HEADROOM && are_last_partitions_empty?(HEADROOM)
        end

        def partition_name(lower_bound)
          "#{table_name}_#{lower_bound}"
        end

        def last_partition
          current_partitions.last
        end

        def partition_for(upper_bound:, lower_bound:, partition_name:)
          IntRangePartition.new(table_name, lower_bound, upper_bound, partition_name: partition_name)
        end
      end
    end
  end
end
