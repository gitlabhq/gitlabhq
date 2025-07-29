# frozen_string_literal: true

module Gitlab
  module Database
    class CollationChecker
      include Gitlab::Database::Migrations::TimeoutHelpers

      COLLATION_VERSION_MISMATCH_QUERY = <<~SQL
          SELECT
            collname AS collation_name,
            collprovider AS provider,
            collversion AS stored_version,
            pg_collation_actual_version(oid) AS actual_version,
            collversion <> pg_collation_actual_version(oid) AS has_mismatch
          FROM
            pg_collation
          WHERE
            collprovider IN ('c', 'd')
          AND (collversion IS DISTINCT FROM pg_collation_actual_version(oid));
      SQL

      # Few Tables/indexes prone to corruption issues for spot check
      # based on the issue: https://gitlab.com/gitlab-org/gitlab/-/issues/505982
      INDEXES_TO_SPOT_CHECK = {
        'main' => {
          'merge_request_diff_commit_users' => %w[
            index_merge_request_diff_commit_users_on_name_and_email
            index_merge_request_diff_commit_users_on_org_id_name_email
          ]
        }
      }.freeze

      INDEXES_TO_SPOT_CHECK_QUERY = <<~SQL
          SELECT DISTINCT
              indrelid::regclass::text AS table_name,
              indexrelid::regclass::text AS index_name,
              string_agg(a.attname, ', ' ORDER BY a.attnum) AS affected_columns,
              i.indisunique AS is_unique,
              pg_relation_size(indexrelid) AS size_bytes
          FROM
              pg_index i
          JOIN
              pg_class idx ON idx.oid = i.indexrelid
          JOIN
              pg_class tbl ON tbl.oid = i.indrelid
          JOIN
              pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
          WHERE
              idx.relname IN (%{indexes_to_spot_check})
          GROUP BY
              i.indexrelid, i.indrelid, i.indisunique, idx.relname, indrelid::regclass::text, indexrelid::regclass::text
          ORDER BY
              table_name, index_name;
      SQL

      def self.run(database_name: nil, logger: Gitlab::AppLogger)
        results = {}

        Gitlab::Database::EachDatabase.each_connection(only: database_name) do |connection, database|
          results[database] = new(connection, database, logger).run
        end

        results
      end

      attr_reader :connection, :database_name, :logger

      def initialize(connection, database_name, logger)
        @connection = connection
        @database_name = database_name
        @logger = logger
      end

      def run
        result = {
          'collation_mismatches' => [],
          'corrupted_indexes' => []
        }

        logger.info("Checking for PostgreSQL collation mismatches on #{database_name} database...")

        result['collation_mismatches'] = check_collation_mismatches

        indexes_to_spot_check = transform_indexes_to_spot_check
        logger.info("Found #{indexes_to_spot_check.count} indexes to corruption spot check.")

        if indexes_to_spot_check.any?
          result['corrupted_indexes'] = identify_corrupted_indexes(indexes_to_spot_check)
          log_results(result['corrupted_indexes'])
        else
          logger.info("No indexes found for corruption spot check.")
        end

        result
      end

      private

      def execute(sql)
        connection.execute(sql) # rubocop:disable Database/AvoidUsingConnectionExecute -- Required for TimeoutHelpers
      end

      def check_collation_mismatches
        mismatched = connection.select_all(COLLATION_VERSION_MISMATCH_QUERY).to_a

        if mismatched.any?
          logger.warn("Collation mismatches detected on #{database_name} database!")
          logger.warn("#{mismatched.count} collation(s) have version mismatches:")
          mismatched.each do |row|
            logger.warn(
              "  - #{row['collation_name']}: stored=#{row['stored_version']}, actual=#{row['actual_version']}"
            )
          end
        else
          logger.info("No collation version mismatches detected on #{database_name}.")
        end

        mismatched
      end

      def transform_indexes_to_spot_check
        indexes_to_spot_check = []

        return indexes_to_spot_check unless INDEXES_TO_SPOT_CHECK.key?(database_name)

        INDEXES_TO_SPOT_CHECK[database_name].each do |table_name, index_names|
          temp = index_names.map { |idx_name| { 'table_name' => table_name, 'index_name' => idx_name } }
          indexes_to_spot_check.concat(temp)
        end

        indexes_to_spot_check
      end

      def identify_corrupted_indexes(indexes)
        return [] if indexes.empty?

        corrupted_indexes = []

        duplicates = check_unique_index_duplicates(fetch_index_info(indexes).select { |idx| unique?(idx) })
        duplicates.each do |idx|
          corruption_info = {
            'index_name' => idx['index_name'],
            'table_name' => idx['table_name'],
            'affected_columns' => idx['affected_columns'],
            'is_unique' => true,
            'size_bytes' => idx['size_bytes'].to_i,
            'corruption_types' => ['duplicates'],
            'needs_deduplication' => true
          }

          corrupted_indexes << corruption_info
        end

        corrupted_indexes
      end

      def log_results(corrupted_indexes)
        if corrupted_indexes.any?
          logger.warn("#{corrupted_indexes.count} corrupted indexes detected!")
          logger.warn("Affected indexes that need to be rebuilt:")
          corrupted_indexes.each do |idx|
            log_index_details(idx)
          end

          provide_remediation_guidance(corrupted_indexes)
        else
          logger.info("No corrupted indexes detected.")
        end
      end

      def log_index_details(idx)
        logger.warn("  - #{idx['index_name']} on table #{idx['table_name']}")
        logger.warn("    • Issues detected: #{idx['corruption_types'].join(', ')}")

        return unless idx['is_unique']

        logger.warn("    • Affected columns: #{idx['affected_columns']}")
        logger.warn("    • Needs deduplication: Yes")
      end

      def unique?(index)
        Gitlab::Utils.to_boolean(index['is_unique'])
      end

      def fetch_index_info(indexes)
        result = []

        return result if indexes.empty?

        quoted_index_names = indexes.map { |idx| connection.quote(idx['index_name']) }.join(',')
        sql = format(INDEXES_TO_SPOT_CHECK_QUERY, indexes_to_spot_check: quoted_index_names)

        disable_statement_timeout do
          result = connection.select_all(sql).to_a
        end

        result
      end

      def check_unique_index_duplicates(indexes)
        duplicate_indexes = []

        return duplicate_indexes if indexes.empty?

        indexes.each do |idx|
          all_key_columns = idx['affected_columns'].split(', ')
          next if all_key_columns.empty?

          all_key_columns.map! { |col| connection.quote_column_name(col) }

          cols_str = all_key_columns.join(', ')
          not_null_conditions = all_key_columns.map { |col| "#{col} IS NOT NULL" }.join(' AND ')

          sql = <<~SQL
              SELECT 1
              FROM (
                SELECT #{cols_str}
                FROM #{connection.quote_table_name(idx['table_name'])}
                WHERE #{not_null_conditions}
                GROUP BY #{cols_str}
                HAVING COUNT(*) > 1
                LIMIT 1
              ) AS dups
          SQL

          duplicates_exist = false
          disable_statement_timeout do
            duplicates_exist = connection.select_value(sql).present?
          end

          if duplicates_exist
            logger.warn("Found duplicates in unique index #{idx['index_name']}")
            duplicate_indexes << idx
          end
        end

        duplicate_indexes
      end

      def provide_remediation_guidance(corrupted_indexes)
        log_remediation_header
        log_duplicate_entry_fixes(corrupted_indexes)
        log_index_rebuild_commands(corrupted_indexes)
        log_collation_refresh_commands
        log_conclusion
      end

      def log_remediation_header
        logger.warn("\nREMEDIATION STEPS:")
        logger.warn("1. Put GitLab into maintenance mode")
        logger.warn("2. Run the following SQL commands:")
      end

      def log_duplicate_entry_fixes(corrupted_indexes)
        indexes_needing_deduplication = corrupted_indexes.select { |idx| idx['needs_deduplication'] }
        return unless indexes_needing_deduplication.any?

        logger.warn("\n# Step 1: Fix duplicate entries in unique indexes")
        indexes_needing_deduplication.each do |idx|
          logger.warn("-- Fix duplicates in #{idx['table_name']} (unique index: #{idx['index_name']})")

          columns = idx['affected_columns'].split(', ')
          cols_str = columns.join(', ')
          not_null_conditions = columns.map do |col|
            "#{col} IS NOT NULL"
          end.join(' AND ')

          logger.warn(
            "SELECT #{cols_str}, COUNT(*), ARRAY_AGG(id) " \
              "FROM #{idx['table_name']} " \
              "WHERE #{not_null_conditions} " \
              "GROUP BY #{cols_str} HAVING COUNT(*) > 1;"
          )
        end

        logger.warn("\n# Use gitlab:db:deduplicate_tags or similar tasks " \
          "to fix these duplicate entries before rebuilding indexes.")
      end

      def log_index_rebuild_commands(corrupted_indexes)
        return unless corrupted_indexes.any?

        logger.warn("\n# Step 2: Rebuild affected indexes")
        logger.warn("# Option A: Rebuild individual indexes with minimal downtime:")
        corrupted_indexes.each do |idx|
          logger.warn("REINDEX INDEX CONCURRENTLY #{idx['index_name']};")
        end

        logger.warn("\n# Option B: Alternatively, rebuild all indexes at once (requires downtime):")
        logger.warn("REINDEX DATABASE #{database_name};")
      end

      def log_collation_refresh_commands
        logger.warn("\n# Step 3: Refresh collation versions")
        logger.warn("ALTER DATABASE #{database_name} REFRESH COLLATION VERSION;")
        logger.warn("-- This updates all collation versions in the database to match the current OS")
      end

      def log_conclusion
        logger.warn("\n3. Take GitLab out of maintenance mode")
        logger.warn("\nFor more information, see: https://docs.gitlab.com/administration/postgresql/upgrading_os/")
      end
    end
  end
end
