# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncIndexes
      module MigrationHelpers
        include ::Gitlab::Database::PartitionHelpers

        def unprepare_async_index(table_name, column_name, **options)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_index_creation_available?

          index_name = options[:name] || index_name(table_name, column_name)

          raise 'Specifying index name is mandatory - specify name: argument' unless index_name

          unprepare_async_index_by_name(table_name, index_name)
        end

        def unprepare_async_index_by_name(table_name, index_name, **options)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_index_creation_available?

          PostgresAsyncIndex.find_by(name: index_name).try do |async_index|
            async_index.destroy!
          end
        end

        # Prepares an index for asynchronous creation.
        #
        # Stores the index information in the postgres_async_indexes table to be created later. The
        # index will be always be created CONCURRENTLY, so that option does not need to be given.
        # If an existing asynchronous definition exists with the same name, the existing entry will be
        # updated with the new definition.
        #
        # If the requested index has already been created, it is not stored in the table for
        # asynchronous creation.
        #
        # Note: The `add_index_options` is the same method Rails uses to generate the index creation statements.
        # As such, we can pass index creation options to the method the same as we would standard index creation.
        #
        # Example usage:
        #
        # INITIAL_PIPELINE_INDEX = 'tmp_index_vulnerability_occurrences_id_and_initial_pipline_id'
        # INITIAL_PIPELINE_COLUMNS = [:id, :initial_pipeline_id]
        #
        # prepare_async_index TABLE_NAME, INITIAL_PIPELINE_COLUMNS, name: INITIAL_PIPELINE_INDEX, where: 'initial_pipeline_id IS NULL'

        def prepare_async_index(table_name, column_name, **options)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          if table_partitioned?(table_name)
            raise ArgumentError, 'prepare_async_index can not be used on a partitioned ' \
              'table. Please use prepare_partitioned_async_index on the partitioned table.'
          end

          return unless async_index_creation_available?
          raise "Table #{table_name} does not exist" unless table_exists?(table_name)

          index_name = options[:name] || index_name(table_name, column_name)

          raise 'Specifying index name is mandatory - specify name: argument' unless index_name

          options = options.merge({ algorithm: :concurrently })

          if index_exists?(table_name, column_name, **options)
            Gitlab::AppLogger.warn(
              message: 'Index not prepared because it already exists',
              table_name: table_name,
              index_name: index_name)

            return
          end

          index, algorithm, if_not_exists = add_index_options(table_name, column_name, **options)

          create_index = ActiveRecord::ConnectionAdapters::CreateIndexDefinition.new(index, algorithm, if_not_exists)
          schema_creation = ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaCreation.new(ApplicationRecord.connection)
          definition = schema_creation.accept(create_index)

          async_index = PostgresAsyncIndex.find_or_create_by!(name: index_name) do |rec|
            rec.table_name = table_name
            rec.definition = definition
          end

          async_index.definition = definition
          async_index.save! # No-op if definition is not changed

          Gitlab::AppLogger.info(
            message: 'Prepared index for async creation',
            table_name: async_index.table_name,
            index_name: async_index.name)

          async_index
        end

        def prepare_async_index_from_sql(definition)
          Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.require_ddl_mode!

          return unless async_index_creation_available?

          table_name, index_name = extract_table_and_index_names_from_concurrent_index!(definition)

          if index_name_exists?(table_name, index_name)
            Gitlab::AppLogger.warn(
              message: 'Index not prepared because it already exists',
              table_name: table_name,
              index_name: index_name)

            return
          end

          async_index = Gitlab::Database::AsyncIndexes::PostgresAsyncIndex.find_or_create_by!(name: index_name) do |rec|
            rec.table_name = table_name
            rec.definition = definition.to_s.strip
          end

          Gitlab::AppLogger.info(
            message: 'Prepared index for async creation',
            table_name: async_index.table_name,
            index_name: async_index.name)

          async_index
        end

        # Prepares an index for asynchronous destruction.
        #
        # Stores the index information in the postgres_async_indexes table to be removed later. The
        # index will be always be removed CONCURRENTLY, so that option does not need to be given.
        # Except for partitioned tables where indexes cannot be dropped using this option.
        # https://www.postgresql.org/docs/current/sql-dropindex.html
        #
        # If the requested index has already been removed, it is not stored in the table for
        # asynchronous destruction.
        def prepare_async_index_removal(table_name, column_name, options = {})
          index_name = options.fetch(:name)
          raise 'prepare_async_index_removal must get an index name defined' if index_name.blank?

          unless index_exists?(table_name, column_name, **options)
            Gitlab::AppLogger.warn "Index not removed because it does not exist (this may be due to an aborted migration or similar): table_name: #{table_name}, index_name: #{index_name}"
            return
          end

          definition = if table_partitioned?(table_name)
                         "DROP INDEX #{quote_column_name(index_name)}"
                       else
                         "DROP INDEX CONCURRENTLY #{quote_column_name(index_name)}"
                       end

          async_index = PostgresAsyncIndex.find_or_create_by!(name: index_name) do |rec|
            rec.table_name = table_name
            rec.definition = definition
          end

          Gitlab::AppLogger.info(
            message: 'Prepared index for async destruction',
            table_name: async_index.table_name,
            index_name: async_index.name
          )

          async_index
        end

        def async_index_creation_available?
          table_exists?(:postgres_async_indexes)
        end

        private

        delegate :table_exists?, to: :connection, private: true

        def extract_table_and_index_names_from_concurrent_index!(definition)
          statement = index_statement_from!(definition)

          raise 'Index statement not found!' unless statement
          raise 'Index must be created concurrently!' unless statement.concurrent
          raise 'Table does not exist!' unless table_exists?(statement.relation.relname)

          [statement.relation.relname, statement.idxname]
        end

        # This raises `PgQuery::ParseError` if the given statement
        # is syntactically incorrect, therefore, validates that the
        # index definition is correct.
        def index_statement_from!(definition)
          parsed_query = PgQuery.parse(definition)

          parsed_query.tree.stmts[0].stmt.index_stmt
        end
      end
    end
  end
end
