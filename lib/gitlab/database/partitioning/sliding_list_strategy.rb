# frozen_string_literal: true

module Gitlab
  module Database
    module Partitioning
      class SlidingListStrategy
        attr_reader :model, :partitioning_key, :next_partition_if, :detach_partition_if, :analyze_interval

        delegate :table_name, to: :model

        def initialize(model, partitioning_key, next_partition_if:, detach_partition_if:, analyze_interval: nil)
          @model = model
          @partitioning_key = partitioning_key
          @next_partition_if = next_partition_if
          @detach_partition_if = detach_partition_if
          @analyze_interval = analyze_interval

          ensure_partitioning_column_ignored_or_readonly!
        end

        def current_partitions
          Gitlab::Database::PostgresPartition.for_parent_table(table_name).map do |partition|
            SingleNumericListPartition.from_sql(table_name, partition.name, partition.condition)
          end.sort
        end

        def missing_partitions
          if no_partitions_exist?
            [initial_partition]
          elsif next_partition_if.call(active_partition)
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

          extra = possibly_extra.take_while { |p| detach_partition_if.call(p) }

          default_value = current_default_value
          if extra.any? { |p| p.value == default_value }
            Gitlab::AppLogger.error(
              message: "Inconsistent partition detected: partition with value #{current_default_value} should " \
                        "not be deleted because it's used as the default value.",
              partition_number: current_default_value,
              table_name: model.table_name
            )

            extra = extra.reject { |p| p.value == default_value }
          end

          extra
        end

        # The partition manager is initialized with both connections and creates
        # partitions in both databases, but here we change the default on the model's
        # connection, meaning that it will not respect the manager's connection config
        # so we need to check that it's changing the default only when called
        # with the model's connection. Also since we prevent writes in the other
        # database, we should not change the default there.
        #
        def after_adding_partitions
          if different_connection_names?
            Gitlab::AppLogger.warn(
              message: 'Skipping changing column default because connections mismatch',
              event: :partition_manager_after_adding_partitions_connection_mismatch,
              model_connection_name: Gitlab::Database.db_config_name(model.connection),
              shared_connection_name: Gitlab::Database.db_config_name(Gitlab::Database::SharedModel.connection),
              table_name: model.table_name
            )

            return
          end

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

        def validate_and_fix
          if different_connection_names?
            Gitlab::AppLogger.warn(
              message: 'Skipping fixing column default because connections mismatch',
              event: :partition_manager_validate_and_fix_connection_mismatch,
              model_connection_name: Gitlab::Database.db_config_name(model.connection),
              shared_connection_name: Gitlab::Database.db_config_name(Gitlab::Database::SharedModel.connection),
              table_name: model.table_name
            )

            return
          end

          return if no_partitions_exist?

          old_default_value = current_default_value
          expected_default_value = active_partition.value

          if old_default_value != expected_default_value
            with_lock_retries do
              model.connection.execute("LOCK TABLE #{model.table_name} IN ACCESS EXCLUSIVE MODE")

              old_default_value = current_default_value
              expected_default_value = active_partition.value

              if old_default_value == expected_default_value
                Gitlab::AppLogger.warn(
                  message: "Table partitions or partition key default value have been changed by another process",
                  table_name: table_name,
                  default_value: expected_default_value
                )
                raise ActiveRecord::Rollback
              end

              model.connection.change_column_default(model.table_name, partitioning_key, expected_default_value)
              Gitlab::AppLogger.warn(
                message: "Fixed default value of sliding_list_strategy partitioning_key",
                column: partitioning_key,
                table_name: table_name,
                connection_name: model.connection.pool.db_config.name,
                old_value: old_default_value,
                new_value: expected_default_value
              )
            end
          end
        end

        private

        def different_connection_names?
          model.connection_db_config.name !=
            Gitlab::Database.db_config_name(Gitlab::Database::SharedModel.connection)
        end

        def current_default_value
          column_name = model.connection.quote(partitioning_key)
          table_name = model.connection.quote(model.table_name)

          value = model.connection.select_value <<~SQL
          SELECT columns.column_default AS default_value
          FROM information_schema.columns columns
          WHERE columns.column_name = #{column_name} AND columns.table_name = #{table_name}
          SQL

          raise "No default value found for the #{partitioning_key} column within #{model.name}" if value.nil?

          Integer(value)
        end

        def ensure_partitioning_column_ignored_or_readonly!
          unless key_ignored_or_readonly?
            raise "Add #{partitioning_key} to #{model.name}.ignored_columns or " \
                  "mark it as readonly to use it with SlidingListStrategy"
          end
        end

        def key_ignored_or_readonly?
          model.ignored_columns.include?(partitioning_key.to_s) || model.readonly_attribute?(partitioning_key.to_s)
        end

        def with_lock_retries(&block)
          Gitlab::Database::Partitioning::WithPartitioningLockRetries.new(
            klass: self.class,
            logger: Gitlab::AppLogger,
            connection: model.connection
          ).run(raise_on_exhaustion: true, &block)
        end
      end
    end
  end
end
