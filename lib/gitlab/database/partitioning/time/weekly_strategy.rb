# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      module Time
        class WeeklyStrategy < BaseStrategy
          HEADROOM = 4.weeks
          PARTITION_SUFFIX = '%Y%m%d'

          # Anchor weeks to Monday explicitly so partition boundaries are
          # deterministic regardless of the application's beginning_of_week setting.
          WEEK_START = :monday

          def current_partitions
            ensure_connection_set

            Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
              TimePartition.from_sql(table_name, partition.name, partition.condition)
            end
          end

          def missing_partitions
            ensure_connection_set

            desired_partitions - current_partitions
          end

          def extra_partitions
            ensure_connection_set

            partitions = current_partitions - desired_partitions
            partitions.reject!(&:holds_data?) if retain_non_empty_partitions

            partitions
          end

          def desired_partitions
            ensure_connection_set

            [].tap do |parts|
              min_date, max_date = relevant_range

              if pruning_old_partitions? && min_date <= oldest_active_date
                min_date = oldest_active_date
              else
                parts << partition_for(upper_bound: min_date)
              end

              while min_date < max_date
                next_date = min_date.next_week(WEEK_START)

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
            ensure_connection_set

            first_partition = current_partitions.min

            if first_partition
              # Use the earliest known lower bound as the range start.
              # When the first partition is the MINVALUE catch-all its `from` is nil,
              # so fall back to its upper bound as the first real week boundary.
              min_date = first_partition.from || first_partition.to
            end

            min_date ||= oldest_active_date if pruning_old_partitions?
            min_date ||= Date.current
            min_date = min_date.beginning_of_week(WEEK_START)

            max_date = Date.current.end_of_week(WEEK_START) + HEADROOM

            [min_date, max_date]
          end

          # no explicit connection needed since no queries are executed (pure date math on static value)
          def oldest_active_date
            retain_for.ago.beginning_of_week(WEEK_START).to_date
          end

          # no explicit connection needed since no queries are executed (pure string formatting on static value)
          def partition_name(lower_bound)
            suffix = lower_bound&.strftime(PARTITION_SUFFIX) || '00000000'

            "#{table_name}_#{suffix}"
          end
        end
      end
    end
  end
end
