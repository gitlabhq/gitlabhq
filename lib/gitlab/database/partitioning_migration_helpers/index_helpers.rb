# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module IndexHelpers
        include Gitlab::Database::MigrationHelpers
        include Gitlab::Database::SchemaHelpers

        # Concurrently creates a new index on a partitioned table. In concept this works similarly to
        # `add_concurrent_index`, and won't block reads or writes on the table while the index is being built.
        #
        # A special helper is required for partitioning because Postgres does not support concurrently building indexes
        # on partitioned tables. This helper concurrently adds the same index to each partition, and creates the final
        # index on the parent table once all of the partitions are indexed. This is the recommended safe way to add
        # indexes to partitioned tables.
        #
        # Example:
        #
        #     add_concurrent_partitioned_index :users, :some_column
        #
        # See Rails' `add_index` for more info on the available arguments.
        def add_concurrent_partitioned_index(table_name, column_names, options = {})
          raise ArgumentError, 'A name is required for indexes added to partitioned tables' unless options[:name]

          partitioned_table = find_partitioned_table(table_name)

          if index_name_exists?(table_name, options[:name])
            Gitlab::AppLogger.warn "Index not created because it already exists (this may be due to an aborted" \
              " migration or similar): table_name: #{table_name}, index_name: #{options[:name]}"

            return
          end

          partitioned_table.postgres_partitions.order(:name).each do |partition|
            partition_index_name = generated_index_name(partition.identifier, options[:name])
            partition_options = options.merge(name: partition_index_name)

            add_concurrent_index(partition.identifier, column_names, partition_options)
          end

          with_lock_retries do
            add_index(table_name, column_names, **options)
          end
        end

        # Safely removes an existing index from a partitioned table. The method name is a bit inaccurate as it does not
        # drop the index concurrently, but it's named as such to maintain consistency with other similar helpers, and
        # indicate that this should be safe to use in a production environment.
        #
        # In current versions of Postgres it's impossible to drop an index concurrently, or drop an index from an
        # individual partition that exists across the entire partitioned table. As a result this helper drops the index
        # from the parent table, which automatically cascades to all partitions. While this does require an exclusive
        # lock, dropping an index is a fast operation that won't block the table for a significant period of time.
        #
        # Example:
        #
        #     remove_concurrent_partitioned_index_by_name :users, 'index_name_goes_here'
        def remove_concurrent_partitioned_index_by_name(table_name, index_name)
          find_partitioned_table(table_name)

          unless index_name_exists?(table_name, index_name)
            Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted " \
              "migration or similar): table_name: #{table_name}, index_name: #{index_name}"

            return
          end

          with_lock_retries do
            remove_index(table_name, name: index_name)
          end
        end

        private

        def find_partitioned_table(table_name)
          partitioned_table = Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(table_name)

          raise ArgumentError, "#{table_name} is not a partitioned table" unless partitioned_table

          partitioned_table
        end

        def generated_index_name(partition_name, index_name)
          object_name("#{partition_name}_#{index_name}", 'index')
        end
      end
    end
  end
end
