# frozen_string_literal: true

module Gitlab
  module Database
    class RepairIndex
      include Gitlab::Database::Migrations::TimeoutHelpers

      BATCH_SIZE = 100
      # SQL templates with placeholders
      REINDEX_SQL = "REINDEX INDEX CONCURRENTLY %{index_name}"
      CREATE_INDEX_SQL = "CREATE%{unique_clause} INDEX CONCURRENTLY %{index_name} ON %{table_name} (%{column_list})"
      UPDATE_REFERENCES_SQL = "UPDATE %{ref_table} SET %{ref_column} = %{good_id} WHERE %{ref_column} IN (%{bad_ids})"
      DELETE_DUPLICATES_SQL = "DELETE FROM %{table_name} WHERE id IN (%{bad_ids})"

      FIND_DUPLICATE_SETS_SQL = <<~SQL
        SELECT ARRAY_AGG(id ORDER BY id ASC) as ids
        FROM %{table_name}
        WHERE %{not_null_conditions}
        GROUP BY %{column_list}
        HAVING COUNT(*) > 1
      SQL
      ENTITIES_WITH_DUPLICATE_REFS_SQL = <<~SQL
        SELECT DISTINCT %{entity_column}
        FROM %{ref_table}
        WHERE %{ref_column} = %{good_id}
        AND EXISTS (
          SELECT 1
          FROM %{ref_table} sub
          WHERE sub.%{entity_column} = %{ref_table}.%{entity_column}
          AND sub.%{ref_column} = %{bad_id}
        )
      SQL
      DELETE_DUPLICATE_REFS_SQL = <<~SQL
        DELETE FROM %{ref_table}
        WHERE %{ref_column} = %{bad_id}
        AND %{entity_column} IN (%{entity_ids})
      SQL
      FIND_ARRAY_REFS_SQL = <<~SQL
        SELECT id, %{array_column}
        FROM %{ref_table}
        WHERE %{array_column}::bigint[] && ARRAY[%{bad_ids}]::bigint[]
      SQL
      UPDATE_ARRAY_REFS_SQL = <<~SQL
        UPDATE %{ref_table}
        SET %{array_column} = ARRAY[%{updated_array}]
        WHERE id = %{record_id}
      SQL
      INDEX_EXISTS_SQL = <<~SQL
        SELECT 1 FROM pg_indexes
        WHERE indexname = %{index_name}
        AND tablename = %{table_name}
      SQL

      # Configuration for known problematic indexes which can be injected via SchemaChecker or CollationChecker
      INDEXES_TO_REPAIR = {
        # Implementation based on scripts to fix index on https://gitlab.com/gitlab-org/gitlab/-/issues/372150#note_1083479615
        # and https://gitlab.com/gitlab-org/gitlab/-/issues/523146#note_2418277173.
        'merge_request_diff_commit_users' => {
          'index_merge_request_diff_commit_users_on_name_and_email' => {
            'columns' => %w[name email],
            'unique' => true,
            'references' => [
              {
                'table' => 'merge_request_diff_commits',
                'column' => 'committer_id'
              },
              {
                'table' => 'merge_request_diff_commits',
                'column' => 'commit_author_id'
              }
            ]
          },
          'index_merge_request_diff_commit_users_on_org_id_name_email' => {
            'columns' => %w[organization_id name email],
            'unique' => true,
            'references' => [
              {
                'table' => 'merge_request_diff_commits',
                'column' => 'committer_id'
              },
              {
                'table' => 'merge_request_diff_commits',
                'column' => 'commit_author_id'
              }
            ]
          }
        }
      }.freeze

      def self.run(database_name: nil, indexes_to_repair: INDEXES_TO_REPAIR, logger: Gitlab::AppLogger, dry_run: false)
        Gitlab::Database::EachDatabase.each_connection(only: database_name) do |connection, database|
          new(connection, database, indexes_to_repair, logger, dry_run).run
        end
      end

      attr_reader :connection, :database_name, :indexes_to_repair, :logger, :dry_run

      def initialize(connection, database_name, indexes_to_repair, logger, dry_run)
        @connection        = connection
        @database_name     = database_name
        @indexes_to_repair = indexes_to_repair
        @logger            = logger
        @dry_run           = dry_run
      end

      def run
        logger.info("DRY RUN: Analysis only, no changes will be made.") if dry_run
        logger.info("Running Index repair on database #{database_name}...")

        indexes_to_repair.each do |table_name, indexes|
          unless table_exists?(table_name)
            logger.info("Table '#{table_name}' does not exist in database #{database_name}. Skipping.")
            next
          end

          indexes.each do |index_name, index_config|
            logger.info("Processing index '#{index_name}' on table '#{table_name}'...")

            if index_config['unique']
              logger.info("Index is unique. Checking for duplicate data...")
              deduplicate_data(table_name, index_config['columns'], index_config['references'])
            end

            if index_exists?(table_name, index_name)
              logger.info("Index exists. Reindexing...")
              reindex_index(index_name)
            else
              logger.info("Index does not exist. Creating new index...")
              create_index(table_name, index_name, index_config['columns'], index_config['unique'])
            end
          end
        end

        logger.info("Index repair completed for database #{database_name}.")
      end

      private

      def execute(sql)
        connection.execute(sql) # rubocop:disable Database/AvoidUsingConnectionExecute -- Required for TimeoutHelpers
      end

      def execute_local(sql, read_only: false)
        logger.info("SQL: #{sql}")

        return if dry_run && !read_only

        disable_statement_timeout do
          yield
        end
      end

      def table_exists?(table_name)
        connection.table_exists?(table_name)
      end

      def index_exists?(table_name, index_name)
        sql = format(
          INDEX_EXISTS_SQL,
          table_name: connection.quote(table_name),
          index_name: connection.quote(index_name)
        )

        execute_local(sql, read_only: true) do
          connection.select_value(sql)
        end.present?
      end

      def deduplicate_data(table_name, columns, references)
        duplicate_sets = find_duplicate_sets(table_name, columns)

        unless duplicate_sets&.any?
          logger.info("No duplicates found in '#{table_name}' for columns: #{columns.join(',')}.")
          return
        end

        logger.warn("Found #{duplicate_sets.count} duplicates in '#{table_name}' for columns: #{columns.join(',')}")

        bad_id_to_good_id_mapping = generate_id_mapping(duplicate_sets)
        process_references(references, bad_id_to_good_id_mapping)
        delete_duplicates(table_name, bad_id_to_good_id_mapping)
      end

      def generate_id_mapping(duplicate_sets)
        id_mapping = {}

        duplicate_sets.each do |set|
          ids = parse_pg_array(set['ids'])
          good_id = ids.first
          bad_ids = ids[1..]

          bad_ids.each do |bad_id|
            id_mapping[bad_id] = good_id
          end
        end

        id_mapping
      end

      def process_references(references, id_mapping)
        return if id_mapping.empty?

        Array(references).each do |ref|
          ref_table = ref['table']
          ref_column = ref['column']
          column_type = ref['type']
          entity_column = ref['entity_column']

          if column_type == 'array'
            handle_array_references(ref_table, ref_column, id_mapping)
          elsif entity_column.present?
            handle_duplicate_references(ref_table, ref_column, entity_column, id_mapping)
          else
            update_references(ref_table, ref_column, id_mapping)
          end
        end
      end

      def handle_array_references(ref_table, ref_column, id_mapping)
        logger.info("Processing array references in '#{ref_table}.#{ref_column}'...")

        id_mapping.keys.each_slice(BATCH_SIZE) do |bad_ids_batch|
          bad_ids_quoted = bad_ids_batch.map { |id| connection.quote(id) }.join(',')

          sql = format(
            FIND_ARRAY_REFS_SQL,
            ref_table: connection.quote_table_name(ref_table),
            array_column: connection.quote_column_name(ref_column),
            bad_ids: bad_ids_quoted
          )

          records = execute_local(sql, read_only: true) do
            connection.select_all(sql)
          end

          next unless records&.any?

          logger.info("Found #{records.count} records with array references to update for this batch")

          records.each do |record|
            record_id = record['id']
            tag_ids = parse_pg_array(record[ref_column])

            updated_tag_ids = tag_ids.map { |tag_id| id_mapping.fetch(tag_id, tag_id) }

            sql = format(
              UPDATE_ARRAY_REFS_SQL,
              ref_table: connection.quote_table_name(ref_table),
              array_column: connection.quote_column_name(ref_column),
              updated_array: updated_tag_ids.join(','),
              record_id: connection.quote(record_id)
            )

            execute_local(sql) do
              connection.update(sql)
            end

            logger.info("Updated array references for record id=#{record_id} in '#{ref_table}'")
          end
        end
      end

      def handle_duplicate_references(ref_table, ref_column, entity_column, id_mapping)
        logger.info("Processing references in '#{ref_table}' with duplicate detection...")

        id_mapping.each do |bad_id, good_id|
          # Find all entities that have both good and bad references
          sql = format(
            ENTITIES_WITH_DUPLICATE_REFS_SQL,
            entity_column: connection.quote_column_name(entity_column),
            ref_table: connection.quote_table_name(ref_table),
            ref_column: connection.quote_column_name(ref_column),
            good_id: connection.quote(good_id),
            bad_id: connection.quote(bad_id)
          )

          entities_with_both = execute_local(sql, read_only: true) do
            connection.select_values(sql)
          end

          next unless entities_with_both&.any?

          entities_with_both.each_slice(BATCH_SIZE) do |entity_ids_batch|
            # Delete the references with bad_id for these entities
            sql = format(
              DELETE_DUPLICATE_REFS_SQL,
              ref_table: connection.quote_table_name(ref_table),
              ref_column: connection.quote_column_name(ref_column),
              bad_id: connection.quote(bad_id),
              entity_column: connection.quote_column_name(entity_column),
              entity_ids: entity_ids_batch.map { |e| connection.quote(e) }.join(',')
            )

            execute_local(sql) do
              deleted_count = connection.delete(sql)
              logger.info("Deleted #{deleted_count} duplicate references in '#{ref_table}' for this batch")
            end
          end
        end

        # update any remaining references
        update_references(ref_table, ref_column, id_mapping)
      end

      def update_references(ref_table, ref_column, id_mapping)
        logger.info("Updating references in '#{ref_table}'...")

        id_mapping.each do |bad_id, good_id|
          sql = format(
            UPDATE_REFERENCES_SQL,
            ref_table: connection.quote_table_name(ref_table),
            ref_column: connection.quote_column_name(ref_column),
            good_id: connection.quote(good_id),
            bad_ids: connection.quote(bad_id)
          )

          execute_local(sql) do
            affected_rows = connection.update(sql)
            logger.info("Updated #{affected_rows} references in '#{ref_table}' from #{bad_id} to #{good_id}")
          end
        end
      end

      def find_duplicate_sets(table_name, columns)
        logger.info("Checking for duplicates in '#{table_name}' for columns: #{columns.join(',')}...")

        not_null_conditions = columns.map do |col|
          "#{connection.quote_column_name(col)} IS NOT NULL"
        end.join(' AND ')

        sql = format(
          FIND_DUPLICATE_SETS_SQL,
          table_name: connection.quote_table_name(table_name),
          column_list: columns.map { |col| connection.quote_column_name(col) }.join(', '),
          not_null_conditions: not_null_conditions
        )

        execute_local(sql, read_only: true) do
          connection.select_all(sql)
        end
      end

      def delete_duplicates(table_name, id_mapping)
        return if id_mapping.empty?

        logger.info("Deleting duplicate records from #{table_name}...")

        id_mapping.keys.each_slice(BATCH_SIZE) do |batch|
          sql = format(
            DELETE_DUPLICATES_SQL,
            table_name: connection.quote_table_name(table_name),
            bad_ids: batch.map { |id| connection.quote(id) }.join(',')
          )

          execute_local(sql) do
            affected_rows = connection.delete(sql)
            logger.info("Deleted #{affected_rows} duplicate records from #{table_name}")
          end
        end
      end

      def reindex_index(index_name)
        logger.info("Reindexing index '#{index_name}'...")

        sql = format(REINDEX_SQL, index_name: connection.quote_table_name(index_name))

        execute_local(sql) do
          execute(sql)
        end

        logger.info("Index reindexed successfully.")
      end

      def create_index(table_name, index_name, columns, unique = false)
        unique_clause = unique ? " UNIQUE" : ""

        sql = format(
          CREATE_INDEX_SQL,
          unique_clause: unique_clause,
          index_name: connection.quote_table_name(index_name),
          table_name: connection.quote_table_name(table_name),
          column_list: columns.map { |col| connection.quote_column_name(col) }.join(', ')
        )

        logger.info("Creating#{unique ? ' unique' : ''} index #{index_name}...")

        execute_local(sql) do
          execute(sql)
        end

        logger.info("Index created successfully.")
      end

      def parse_pg_array(pg_array_string)
        return [] if pg_array_string.nil?

        pg_array_string.tr('{}', '').split(',').map(&:to_i)
      end
    end
  end
end
