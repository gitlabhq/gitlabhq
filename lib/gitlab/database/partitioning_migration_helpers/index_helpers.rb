# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      module IndexHelpers
        include Gitlab::Database::MigrationHelpers
        include Gitlab::Database::SchemaHelpers

        DuplicatedIndexesError = Class.new(StandardError)

        ERROR_SCOPE = 'index'

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
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

          raise ArgumentError, 'A name is required for indexes added to partitioned tables' unless options[:name]

          partitioned_table = find_partitioned_table(table_name)

          if index_name_exists?(table_name, options[:name])
            Gitlab::AppLogger.warn "Index not created because it already exists (this may be due to an aborted" \
              " migration or similar): table_name: #{table_name}, index_name: #{options[:name]}"

            return
          end

          partitioned_table.postgres_partitions.order(:name).each do |partition|
            partition_index_name = generated_index_name(partition.identifier, options[:name])
            partition_options = options.merge(name: partition_index_name, allow_partition: true)

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
          assert_not_in_transaction_block(scope: ERROR_SCOPE)

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

        # Finds duplicate indexes for a given schema and table. This finds
        # indexes where the index definition is identical but the names are
        # different. Returns an array of arrays containing duplicate index name
        # pairs.
        #
        # Example:
        #
        #     find_duplicate_indexes('table_name_goes_here')
        def find_duplicate_indexes(table_name, schema_name: connection.current_schema)
          find_indexes(table_name, schema_name: schema_name)
            .group_by { |r| r['index_id'] }
            .select { |_, v| v.size > 1 }
            .map { |_, indexes| indexes.map { |index| index['index_name'] } }
        end

        # Retrieves a hash of index names for a given table and schema, by index
        # definition.
        #
        # Example:
        #
        #     indexes_by_definition_for_table('table_name_goes_here')
        #
        # Returns:
        #
        #     {
        #       "CREATE _ btree (created_at)" => "index_on_created_at"
        #     }
        def indexes_by_definition_for_table(table_name, schema_name: connection.current_schema)
          duplicate_indexes = find_duplicate_indexes(table_name, schema_name: schema_name)

          unless duplicate_indexes.empty?
            raise DuplicatedIndexesError, "#{table_name} has duplicate indexes: #{duplicate_indexes}"
          end

          find_indexes(table_name, schema_name: schema_name)
            .each_with_object({}) { |row, hash| hash[row['index_id']] = row['index_name'] }
        end

        # Renames indexes for a given table and schema, mapping by index
        # definition, to a hash of new index names.
        #
        # Example:
        #
        #     index_names = indexes_by_definition_for_table('source_table_name_goes_here')
        #     drop_table('source_table_name_goes_here')
        #     rename_indexes_for_table('destination_table_name_goes_here', index_names)
        def rename_indexes_for_table(table_name, new_index_names, schema_name: connection.current_schema)
          current_index_names = indexes_by_definition_for_table(table_name, schema_name: schema_name)
          rename_indexes(current_index_names, new_index_names, schema_name: schema_name)
        end

        private

        def find_indexes(table_name, schema_name: connection.current_schema)
          indexes = connection.select_all(<<~SQL, 'SQL', [schema_name, table_name])
            SELECT n.nspname AS schema_name,
                   c.relname AS table_name,
                   i.relname AS index_name,
                   regexp_replace(pg_get_indexdef(i.oid), 'INDEX .*? USING', '_') AS index_id
            FROM pg_index x
              JOIN pg_class c ON c.oid = x.indrelid
              JOIN pg_class i ON i.oid = x.indexrelid
              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE (c.relkind = ANY (ARRAY['r'::"char", 'm'::"char", 'p'::"char"]))
              AND (i.relkind = ANY (ARRAY['i'::"char", 'I'::"char"]))
              AND n.nspname = $1
              AND c.relname = $2;
          SQL

          indexes.to_a
        end

        def find_partitioned_table(table_name)
          partitioned_table = Gitlab::Database::PostgresPartitionedTable.find_by_name_in_current_schema(table_name)

          raise ArgumentError, "#{table_name} is not a partitioned table" unless partitioned_table

          partitioned_table
        end

        def generated_index_name(partition_name, index_name)
          object_name("#{partition_name}_#{index_name}", 'index')
        end

        def rename_indexes(from, to, schema_name: connection.current_schema)
          indexes_to_rename = from.select { |index_id, _| to.has_key?(index_id) }
          statements = indexes_to_rename.map do |index_id, index_name|
            <<~SQL
              ALTER INDEX #{connection.quote_table_name("#{schema_name}.#{connection.quote_column_name(index_name)}")}
                          RENAME TO #{connection.quote_column_name(to[index_id])}
            SQL
          end

          connection.execute(statements.join(';'))
        end
      end
    end
  end
end
