# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module Time
        class MonthlyStrategy < BaseStrategy
          HEADROOM = 6.months
          PARTITION_SUFFIX = '%Y%m'

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
            partitions = current_partitions - desired_partitions
            partitions.reject!(&:holds_data?) if retain_non_empty_partitions

            partitions
          end

          def partition_name(lower_bound)
            suffix = lower_bound&.strftime(PARTITION_SUFFIX) || '000000'

            "#{table_name}_#{suffix}"
          end

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
            first_partition = current_partitions.min

            if first_partition
              # Case 1: First partition starts with MINVALUE, i.e. from is nil -> start with first real partition
              # Case 2: Rather unexpectedly, first partition does not start with MINVALUE, i.e. from is not nil
              #         In this case, use first partition beginning as a start
              min_date = first_partition.from || first_partition.to
            end

            min_date ||= oldest_active_date if pruning_old_partitions?

            # In case we don't have a partition yet
            min_date ||= Date.current
            min_date = min_date.beginning_of_month

            max_date = Date.current.end_of_month + HEADROOM

            [min_date, max_date]
          end

          def oldest_active_date
            retain_for.ago.beginning_of_month.to_date
          end
        end
      end
    end
  end
end
