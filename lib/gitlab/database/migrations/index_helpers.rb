# frozen_string_literal: true

module Gitlab
  module Database
    module Migrations
      module IndexHelpers
        include TimeoutHelpers
        include ::Gitlab::Database::PartitionHelpers
        include ::Gitlab::Database::AsyncIndexes::MigrationHelpers

        # Creates a new index, concurrently
        #
        # Example:
        #
        #     add_concurrent_index :users, :some_column
        #
        # See Rails' `add_index` for more info on the available arguments.
        def add_concurrent_index(table_name, column_name, options = {})
          if transaction_open?
            raise 'add_concurrent_index can not be run inside a transaction, ' \
              'you can disable transactions by calling disable_ddl_transaction! ' \
              'in the body of your migration class'
          end

          if !options.delete(:allow_partition) && partition?(table_name)
            raise ArgumentError, 'add_concurrent_index can not be used on a partitioned ' \
              'table. Please use add_concurrent_partitioned_index on the partitioned table ' \
              'as we need to create indexes on each partition and an index on the parent table'
          end

          options = options.merge({ algorithm: :concurrently })

          if index_exists?(table_name, column_name, **options)
            name = options[:name] || index_name(table_name, column_name)
            _, schema = table_name.to_s.split('.').reverse

            if index_invalid?(name, schema: schema)
              say "Index being recreated because the existing version was INVALID: table_name: #{table_name}, " \
                "column_name: #{column_name}"

              remove_concurrent_index_by_name(table_name, name)
            else
              say "Index not created because it already exists (this may be due to an aborted migration or similar): " \
                "table_name: #{table_name}, column_name: #{column_name}"

              return
            end
          end

          disable_statement_timeout do
            add_index(table_name, column_name, **options)
          end

          # We created this index. Now let's remove the queuing entry for async creation in case it's still there.
          unprepare_async_index(table_name, column_name, **options)
        end

        # Removes an existed index, concurrently
        #
        # Example:
        #
        #     remove_concurrent_index :users, :some_column
        #
        # See Rails' `remove_index` for more info on the available arguments.
        def remove_concurrent_index(table_name, column_name, options = {})
          if transaction_open?
            raise 'remove_concurrent_index can not be run inside a transaction, ' \
              'you can disable transactions by calling disable_ddl_transaction! ' \
              'in the body of your migration class'
          end

          if partition?(table_name)
            raise ArgumentError, 'remove_concurrent_index can not be used on a partitioned ' \
              'table. Please use remove_concurrent_partitioned_index_by_name on the partitioned table ' \
              'as we need to remove the index on the parent table'
          end

          options = options.merge({ algorithm: :concurrently })

          unless index_exists?(table_name, column_name, **options)
            Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted " \
              "migration or similar): table_name: #{table_name}, column_name: #{column_name}"
            return
          end

          disable_statement_timeout do
            remove_index(table_name, **options.merge({ column: column_name }))
          end

          # We removed this index. Now let's make sure it's not queued for async creation.
          unprepare_async_index(table_name, column_name, **options)
        end

        # Removes an existing index, concurrently
        #
        # Example:
        #
        #     remove_concurrent_index :users, "index_X_by_Y"
        #
        # See Rails' `remove_index` for more info on the available arguments.
        def remove_concurrent_index_by_name(table_name, index_name, options = {})
          if transaction_open?
            raise 'remove_concurrent_index_by_name can not be run inside a transaction, ' \
              'you can disable transactions by calling disable_ddl_transaction! ' \
              'in the body of your migration class'
          end

          if partition?(table_name)
            raise ArgumentError, 'remove_concurrent_index_by_name can not be used on a partitioned ' \
              'table. Please use remove_concurrent_partitioned_index_by_name on the partitioned table ' \
              'as we need to remove the index on the parent table'
          end

          index_name = index_name[:name] if index_name.is_a?(Hash)

          raise 'remove_concurrent_index_by_name must get an index name as the second argument' if index_name.blank?

          options = options.merge({ algorithm: :concurrently })

          unless index_exists_by_name?(table_name, index_name)
            Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted " \
              "migration or similar): table_name: #{table_name}, index_name: #{index_name}"
            return
          end

          disable_statement_timeout do
            remove_index(table_name, **options.merge({ name: index_name }))
          end

          # We removed this index. Now let's make sure it's not queued for async creation.
          unprepare_async_index_by_name(table_name, index_name, **options)
        end

        private

        def index_invalid?(index_name, schema: nil)
          index_name = connection.quote(index_name)
          schema = connection.quote(schema) if schema
          schema ||= 'current_schema()'

          connection.select_value(<<~SQL)
            select not i.indisvalid
            from pg_class c
            inner join pg_index i
              on c.oid = i.indexrelid
            inner join pg_namespace n
              on n.oid = c.relnamespace
            where n.nspname = #{schema}
              and c.relname = #{index_name}
          SQL
        end
      end
    end
  end
end
