# frozen_string_literal: true

module Gitlab
  module Database
    class CollationChecker
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

      def self.run(database_name: nil, logger: Gitlab::AppLogger)
        Gitlab::Database::EachDatabase.each_connection(only: database_name) do |connection, database|
          new(connection, database, logger).run
        end
      end

      attr_reader :connection, :database_name, :logger

      def initialize(connection, database_name, logger)
        @connection = connection
        @database_name = database_name
        @logger = logger
      end

      def run
        result = { mismatches_found: false, affected_indexes: [] }

        logger.info("Checking for PostgreSQL collation mismatches on #{database_name} database...")

        mismatched = mismatched_collations

        if mismatched.empty?
          logger.info("No collation mismatches detected on #{database_name}.")
          return result
        end

        result[:mismatches_found] = true

        logger.warn("⚠️ COLLATION MISMATCHES DETECTED on #{database_name} database!")
        logger.warn("#{mismatched.count} collation(s) have version mismatches:")

        mismatched.each do |row|
          logger.warn(
            "  - #{row['collation_name']}: stored=#{row['stored_version']}, actual=#{row['actual_version']}"
          )
        end

        affected_indexes = find_affected_indexes(mismatched)

        if affected_indexes.empty?
          logger.info("No indexes appear to be affected by the collation mismatches.")
          return result
        end

        result[:affected_indexes] = affected_indexes

        logger.warn("Affected indexes that need to be rebuilt:")
        affected_indexes.each do |row|
          logger.warn("  - #{row['index_name']} (#{row['index_type']}) on table #{row['table_name']}")
          logger.warn("    • Affected columns: #{row['affected_columns']}")
          logger.warn("    • Type: #{unique?(row) ? 'UNIQUE' : 'NON-UNIQUE'}")
        end

        # Provide remediation guidance
        provide_remediation_guidance(affected_indexes)

        result
      end

      private

      # Helper method to check if an index is unique, handling both string and boolean values
      def unique?(index)
        unique = index['is_unique']
        unique == 't' || unique == true || unique == 'true'
      end

      def mismatched_collations
        connection.select_all(COLLATION_VERSION_MISMATCH_QUERY).to_a
      rescue ActiveRecord::StatementInvalid => e
        logger.error("Error checking collation mismatches: #{e.message}")
        []
      end

      def find_affected_indexes(mismatched_collations)
        return [] if mismatched_collations.empty?

        collation_names = mismatched_collations.map { |row| connection.quote(row['collation_name']) }.join(',')

        # Using a more comprehensive query based on PostgreSQL wiki
        # Link: https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected
        query = <<~SQL
            SELECT DISTINCT
                indrelid::regclass::text AS table_name,
                indexrelid::regclass::text AS index_name,
                string_agg(a.attname, ', ' ORDER BY s.attnum) AS affected_columns,
                am.amname AS index_type,
                s.indisunique AS is_unique
            FROM
                (SELECT
                    indexrelid,
                    indrelid,
                    indcollation[j] coll,
                    indkey[j] attnum,
                    indisunique
                 FROM
                    pg_index i,
                    generate_subscripts(indcollation, 1) g(j)
                ) s
            JOIN
                pg_collation c ON coll=c.oid
            JOIN
                pg_class idx ON idx.oid = s.indexrelid
            JOIN
                pg_am am ON idx.relam = am.oid
            JOIN
                pg_attribute a ON a.attrelid = s.indrelid AND a.attnum = s.attnum
            WHERE
                c.collname IN (#{collation_names})
            GROUP BY
                s.indexrelid, s.indrelid, s.indisunique, index_name, table_name, am.amname
            ORDER BY
                table_name,
                index_name;
        SQL

        connection.select_all(query).to_a
      rescue ActiveRecord::StatementInvalid => e
        logger.error("Error finding affected indexes: #{e.message}")
        []
      end

      def provide_remediation_guidance(affected_indexes)
        log_remediation_header
        log_duplicate_entry_checks(affected_indexes)
        log_index_rebuild_commands(affected_indexes)
        log_collation_refresh_commands
        log_conclusion
      end

      def log_remediation_header
        logger.warn("\nREMEDIATION STEPS:")
        logger.warn("1. Put GitLab into maintenance mode")
        logger.warn("2. Run the following SQL commands:")
      end

      def log_duplicate_entry_checks(affected_indexes)
        # Use the unique? helper method for consistency
        unique_indexes = affected_indexes.select { |idx| unique?(idx) }
        return unless unique_indexes.any?

        logger.warn("\n# Step 1: Check for duplicate entries in unique indexes")
        unique_indexes.each do |idx|
          logger.warn("-- Check for duplicates in #{idx['table_name']} (unique index: #{idx['index_name']})")
          columns = idx['affected_columns'].split(', ')
          cols_str = columns.join(', ')

          logger.warn(
            "SELECT #{cols_str}, COUNT(*), ARRAY_AGG(id) " \
              "FROM #{idx['table_name']} " \
              "GROUP BY #{cols_str} HAVING COUNT(*) > 1 LIMIT 1;"
          )
        end

        logger.warn("\n# If duplicates exist, you may need to use gitlab:db:deduplicate_tags or similar tasks")
        logger.warn("# to fix duplicate entries before rebuilding unique indexes.")
      end

      def log_index_rebuild_commands(affected_indexes)
        return unless affected_indexes.any?

        logger.warn("\n# Step 2: Rebuild affected indexes")
        logger.warn("# Option A: Rebuild individual indexes with minimal downtime:")
        affected_indexes.each do |row|
          logger.warn("REINDEX INDEX #{row['index_name']} CONCURRENTLY;")
        end

        logger.warn("\n# Option B: Alternatively, rebuild all indexes at once (requires downtime):")
        logger.warn("REINDEX DATABASE #{database_name};")
      end

      def log_collation_refresh_commands
        # Customer reported this command as working: https://gitlab.com/groups/gitlab-org/-/epics/8573#note_2513370623
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
