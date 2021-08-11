# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class MonthlyStrategy
        attr_reader :model, :partitioning_key, :retain_for

        # We create this many partitions in the future
        HEADROOM = 6.months

        delegate :table_name, to: :model

        def initialize(model, partitioning_key, retain_for: nil)
          @model = model
          @partitioning_key = partitioning_key
          @retain_for = retain_for
        end

        def current_partitions
          Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            TimePartition.from_sql(table_name, partition.name, partition.condition)
          end
        end

        # Check the currently existing partitions and determine which ones are missing
        def missing_partitions
          desired_partitions - current_partitions
        end

        def extra_partitions
          current_partitions - desired_partitions
        end

        private

        def desired_partitions
          [].tap do |parts|
            min_date, max_date = relevant_range

            if pruning_old_partitions? && min_date <= oldest_active_date
              min_date = oldest_active_date.beginning_of_month
            else
              parts << partition_for(upper_bound: min_date)
            end

            while min_date < max_date
              next_date = min_date.next_month

              parts << partition_for(lower_bound: min_date, upper_bound: next_date)

              min_date = next_date
            end
          end
        end

        # This determines the relevant time range for which we expect to have data
        # (and therefore need to create partitions for).
        #
        # Note: We typically expect the first partition to be half-unbounded, i.e.
        #       to start from MINVALUE to a specific date `x`. The range returned
        #       does not include the range of the first, half-unbounded partition.
        def relevant_range
          if (first_partition = current_partitions.min)
            # Case 1: First partition starts with MINVALUE, i.e. from is nil -> start with first real partition
            # Case 2: Rather unexpectedly, first partition does not start with MINVALUE, i.e. from is not nil
            #         In this case, use first partition beginning as a start
            min_date = first_partition.from || first_partition.to
          end

          if pruning_old_partitions?
            min_date ||= oldest_active_date
          end

          # In case we don't have a partition yet
          min_date ||= Date.today
          min_date = min_date.beginning_of_month

          max_date = Date.today.end_of_month + HEADROOM

          [min_date, max_date]
        end

        def partition_for(lower_bound: nil, upper_bound:)
          TimePartition.new(table_name, lower_bound, upper_bound)
        end

        def pruning_old_partitions?
          retain_for.present?
        end

        def oldest_active_date
          (Date.today - retain_for).beginning_of_month
        end

        def connection
          ActiveRecord::Base.connection
        end
      end
    end
  end
end
