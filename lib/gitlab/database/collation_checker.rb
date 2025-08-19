# frozen_string_literal: true

module Gitlab
  module Database
    class CollationChecker
      include Gitlab::Database::Migrations::TimeoutHelpers

      # Maximum table size in bytes for running duplicate checks
      MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK = 1.gigabyte

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
          ],
          'topics' => ['index_topics_on_organization_id_and_name'],
          'ci_refs' => ['index_ci_refs_on_project_id_and_ref_path'],
          'ci_resource_groups' => ['index_ci_resource_groups_on_project_id_and_key'],
          'environments' => ['index_environments_on_project_id_and_name'],
          'sbom_components' => ['idx_sbom_components_on_name_purl_type_component_type_and_org_id'],
          'tags' => ['index_tags_on_name']
        }
      }.freeze

      INDEXES_TO_SPOT_CHECK_QUERY = <<~SQL
          SELECT DISTINCT
              indrelid::regclass::text AS table_name,
              indexrelid::regclass::text AS index_name,
              string_agg(a.attname, ', ' ORDER BY a.attnum) AS affected_columns,
              i.indisunique AS is_unique,
              pg_relation_size(indexrelid) AS index_size_bytes,
              pg_relation_size(indrelid) AS table_size_bytes
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

      def self.run(database_name: nil, logger: Gitlab::AppLogger, max_table_size: MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK)
        results = {}

        Gitlab::Database::EachDatabase.each_connection(only: database_name) do |connection, database|
          results[database] = new(connection, database, logger, max_table_size).run
        end

        results
      end

      attr_reader :connection, :database_name, :logger, :max_table_size

      def initialize(connection, database_name, logger, max_table_size)
        @connection = connection
        @database_name = database_name
        @logger = logger
        @max_table_size = max_table_size
      end

      def run
        result = {
          'collation_mismatches' => [],
          'corrupted_indexes' => [],
          'skipped_indexes' => []
        }

        logger.info("Checking for PostgreSQL collation mismatches on #{database_name} database...")

        result['collation_mismatches'] = check_collation_mismatches

        indexes_to_spot_check = transform_indexes_to_spot_check
        logger.info("Found #{indexes_to_spot_check.count} indexes to corruption spot check.")

        if indexes_to_spot_check.any?
          index_info = fetch_index_info(indexes_to_spot_check)

          # Identify which indexes should be skipped due to size
          large_indexes = index_info.select { |idx| idx['table_size_bytes'].to_i > max_table_size }
          if large_indexes.any?
            logger.info("Skipping duplicate checks for #{large_indexes.count} indexes due to large table size")
            large_indexes.each do |idx|
              logger.info("  - Skipping #{idx['index_name']} on table #{idx['table_name']} " \
                "(table size: #{human_size(idx['table_size_bytes'].to_i)})")

              # Add to skipped checks with reason
              result['skipped_indexes'] << {
                'index_name' => idx['index_name'],
                'table_name' => idx['table_name'],
                'table_size_bytes' => idx['table_size_bytes'].to_i,
                'index_size_bytes' => idx['index_size_bytes'].to_i,
                'table_size_threshold' => max_table_size,
                'reason' => 'table_size_exceeds_threshold'
              }
            end
          end

          # Check duplicates only for tables under the size threshold
          result['corrupted_indexes'] = identify_corrupted_indexes(index_info - large_indexes)
          log_results(result['corrupted_indexes'], result['skipped_indexes'])
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

        duplicates = check_unique_index_duplicates(indexes.select { |idx| unique?(idx) })
        duplicates.each do |idx|
          corruption_info = {
            'index_name' => idx['index_name'],
            'table_name' => idx['table_name'],
            'affected_columns' => idx['affected_columns'],
            'is_unique' => true,
            'table_size_bytes' => idx['table_size_bytes'].to_i,
            'index_size_bytes' => idx['index_size_bytes'].to_i,
            'corruption_types' => ['duplicates'],
            'needs_deduplication' => true
          }

          corrupted_indexes << corruption_info
        end

        corrupted_indexes
      end

      def log_results(corrupted_indexes, skipped_indexes = [])
        if corrupted_indexes.any?
          logger.warn("#{corrupted_indexes.count} corrupted indexes detected!")
          logger.warn("Affected indexes that need to be rebuilt:")
          corrupted_indexes.each do |idx|
            log_index_details(idx)
          end

          provide_remediation_guidance(corrupted_indexes)
        elsif skipped_indexes.any?
          logger.warn("No corrupted indexes detected in checked indexes, " \
            "but #{skipped_indexes.count} indexes were skipped.")
          logger.warn("Consider running checks on these indexes with a higher timeout or offline.")
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
            connection.transaction do
              connection.execute("SET LOCAL enable_indexscan TO off") # rubocop:disable Database/AvoidUsingConnectionExecute -- session configuration
              connection.execute("SET LOCAL enable_bitmapscan TO off") # rubocop:disable Database/AvoidUsingConnectionExecute -- session configuration

              duplicates_exist = connection.select_value(sql).present?
            end
          end

          if duplicates_exist
            logger.warn("Found duplicates in unique index #{idx['index_name']}")
            duplicate_indexes << idx
          end
        end

        duplicate_indexes
      end

      def human_size(bytes)
        ActiveSupport::NumberHelper.number_to_human_size(bytes, precision: 1)
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
