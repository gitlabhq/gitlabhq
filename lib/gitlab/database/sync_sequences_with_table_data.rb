# frozen_string_literal: true

module Gitlab
  module Database
    # Advances every sequence to the maximum value present in its consumer
    # tables. Required before promoting a Geo site replicated with PostgreSQL
    # logical replication: LR copies table rows but never sequence values, so
    # after promotion the first INSERT would reuse an existing ID and fail
    # with a unique constraint violation.
    #
    # A sequence's consumers are all tables reachable through either a
    # `nextval` column default or an OWNED BY link. Both sources are needed:
    # a sequence can back tables beyond its owner (web_hook_logs_daily_id_seq
    # spans ~25 root tables, audit_events_id_seq is OWNED BY NONE), while the
    # `p_ci_*` family assigns IDs through `assign_*_id_value()` triggers with
    # no column default at all, leaving ownership as its only catalog trace.
    # The target value must be the maximum across all consumers. The
    # postgres_sequences view (Gitlab::Database::PostgresSequence) cannot be
    # reused here: it covers only the OWNED BY half, without schema
    # qualification or partition-root resolution.
    #
    # rubocop:disable Rails/Output -- Runs from rake tasks during Geo failover; the operator needs terminal output
    class SyncSequencesWithTableData
      include Gitlab::Loggable

      # Absorbs IDs consumed between the MAX() read and the setval by any
      # application process still running against the writable secondary. It
      # does not protect against rows the old primary allocated to
      # since-deleted data: MAX() is a lower bound on the old sequence
      # position, so pruned tables can see IDs reissued after failover.
      SEQUENCE_BUFFER = 1000

      Error = Class.new(StandardError)
      SyncError = Class.new(Error)

      # Finds every (sequence -> consumer table) pair from both catalog
      # sources. Partition children are resolved to their root parent table
      # (its max spans all partitions), and consumer tables are returned
      # schema-qualified because partitions live outside the search_path.
      SEQUENCES_WITH_CONSUMERS_SQL = <<~SQL
        WITH RECURSIVE consumers AS (
          SELECT
            ad.adrelid AS table_oid,
            a.attname AS col_name,
            to_regclass((regexp_match(pg_get_expr(ad.adbin, ad.adrelid), 'nextval\\(''([^'']+)'''))[1]) AS seq_oid
          FROM pg_attrdef ad
          JOIN pg_attribute a ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
          JOIN pg_class tc ON tc.oid = ad.adrelid
          WHERE tc.relkind IN ('r', 'p')
            AND pg_get_expr(ad.adbin, ad.adrelid) LIKE '%nextval(%'
          UNION
          SELECT
            dep.refobjid AS table_oid,
            a.attname AS col_name,
            dep.objid AS seq_oid
          FROM pg_depend dep
          JOIN pg_class s ON s.oid = dep.objid AND s.relkind = 'S'
          JOIN pg_class t ON t.oid = dep.refobjid AND t.relkind IN ('r', 'p')
          JOIN pg_attribute a ON a.attrelid = dep.refobjid AND a.attnum = dep.refobjsubid
          WHERE dep.classid = 'pg_class'::regclass
            AND dep.refclassid = 'pg_class'::regclass
            AND dep.deptype IN ('a', 'i')
        ),
        lineage AS (
          SELECT DISTINCT table_oid AS start_oid, table_oid AS current_oid
          FROM consumers
          UNION ALL
          SELECT lineage.start_oid, pg_inherits.inhparent
          FROM lineage
          JOIN pg_inherits ON pg_inherits.inhrelid = lineage.current_oid
        ),
        roots AS (
          SELECT lineage.start_oid, lineage.current_oid AS root_oid
          FROM lineage
          WHERE NOT EXISTS (
            SELECT 1 FROM pg_inherits WHERE pg_inherits.inhrelid = lineage.current_oid
          )
        )
        SELECT DISTINCT
          seq_ns.nspname AS seq_schema,
          seq_class.relname AS seq_name,
          pg_seq.seqmin AS seq_min,
          pg_seq.seqmax AS seq_max,
          pg_seq.seqstart AS seq_start,
          pg_sequence_last_value(seq_class.oid) AS last_value,
          tbl_ns.nspname AS table_schema,
          tbl.relname AS table_name,
          consumers.col_name AS col_name
        FROM consumers
        JOIN roots ON roots.start_oid = consumers.table_oid
        JOIN pg_class seq_class ON seq_class.oid = consumers.seq_oid
        JOIN pg_namespace seq_ns ON seq_ns.oid = seq_class.relnamespace
        JOIN pg_sequence pg_seq ON pg_seq.seqrelid = seq_class.oid
        JOIN pg_class tbl ON tbl.oid = roots.root_oid
        JOIN pg_namespace tbl_ns ON tbl_ns.oid = tbl.relnamespace
        WHERE consumers.seq_oid IS NOT NULL
      SQL

      ALL_SEQUENCES_SQL = <<~SQL
        SELECT pg_namespace.nspname || '.' || pg_class.relname
        FROM pg_class
        JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relkind = 'S'
          AND pg_namespace.nspname NOT IN ('pg_catalog', 'information_schema')
      SQL

      # A nextval default whose sequence cannot be resolved would silently
      # shrink a sequence's consumer set, so surface any such default.
      UNRESOLVED_NEXTVAL_DEFAULTS_SQL = <<~SQL
        SELECT n.nspname || '.' || c.relname || '.' || a.attname
        FROM pg_attrdef ad
        JOIN pg_class c ON c.oid = ad.adrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_attribute a ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
        WHERE c.relkind IN ('r', 'p')
          AND pg_get_expr(ad.adbin, ad.adrelid) LIKE '%nextval(%'
          AND to_regclass((regexp_match(pg_get_expr(ad.adbin, ad.adrelid), 'nextval\\(''([^'']+)'''))[1]) IS NULL
      SQL

      # only_sequences: optional allowlist of sequence names (unqualified or
      # schema-qualified) to restrict the run, e.g. for scoped re-syncs.
      def initialize(logger: Gitlab::AppLogger, only_sequences: nil)
        @logger = logger
        @only_sequences = only_sequences.presence&.map(&:to_s)
      end

      def execute
        logger.info(build_structured_payload_labkit(
          message: 'Syncing sequences with table data for logical replication promotion'
        ))
        puts 'Syncing sequences with table data (required for logical replication)...'

        advanced_count = 0
        examined_count = 0
        failed_sequences = []

        each_database do |db_name, connection|
          advanced, examined, failed = sync_database_sequences(db_name, connection)
          advanced_count += advanced
          examined_count += examined
          failed_sequences.concat(failed)

          error_suffix = failed.any? ? ", #{failed.size} errors" : ''
          puts "  #{db_name}: advanced #{advanced} of #{examined} sequences#{error_suffix}"
        end

        logger.info(build_structured_payload_labkit(
          message: 'Sequence sync complete',
          advanced: advanced_count, examined: examined_count, error_count: failed_sequences.size
        ))

        if failed_sequences.any?
          raise SyncError, "Sequence sync failed for: #{failed_sequences.join('; ')}. " \
            'Aborting promotion to prevent ID collisions after failover.'
        end

        puts Rainbow("Advanced #{advanced_count} of #{examined_count} sequences").green
      end

      private

      attr_reader :logger, :only_sequences

      def each_database
        Gitlab::Database::EachDatabase.each_connection(include_shared: false) do |connection, db_name|
          yield db_name, connection
        end
      end

      def sync_database_sequences(db_name, connection)
        with_suppressed_query_analyzers do
          without_statement_timeout(connection) do
            sequences = fetch_sequences_with_consumers(connection)
            warn_about_sequences_without_consumers(db_name, connection, sequences)
            warn_about_unresolved_defaults(db_name, connection)

            advanced = 0
            examined = 0
            failed = []

            sequences.each do |seq_name, seq_info|
              examined += 1
              advanced += 1 if sync_single_sequence(db_name, connection, seq_name, seq_info)
            rescue StandardError => e
              failed << "#{seq_name} (#{db_name}): #{e.message}"
              Gitlab::ErrorTracking.track_exception(
                e,
                database: db_name.to_s,
                sequence: seq_name,
                tables: seq_info[:consumers].map { |consumer| consumer[:table] }
              )
            end

            [advanced, examined, failed]
          end
        end
      end

      # The statement timeout would kill MAX() on large unindexed consumers
      # (e.g. loose_foreign_keys_deleted_records) and abort the promotion.
      def without_statement_timeout(connection)
        connection.execute('SET statement_timeout TO 0')
        yield
      ensure
        connection.execute('RESET statement_timeout')
      end

      # Each physical database contains a copy of every table, including
      # tables whose gitlab_schema belongs to another connection (locked
      # after decomposition but still holding rows). The connection/schema
      # analyzer is a test/dev guard for application queries and would
      # reject these maintenance reads.
      def with_suppressed_query_analyzers(&block)
        Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed(&block)
      end

      def fetch_sequences_with_consumers(connection)
        connection.select_all(SEQUENCES_WITH_CONSUMERS_SQL).each_with_object({}) do |row, result|
          qualified_name = "#{row['seq_schema']}.#{row['seq_name']}"
          next unless include_sequence?(row['seq_name'], qualified_name)

          entry = result[qualified_name] ||= {
            seq_schema: row['seq_schema'],
            seq_name: row['seq_name'],
            seq_min: row['seq_min'].to_i,
            seq_max: row['seq_max'].to_i,
            seq_start: row['seq_start'].to_i,
            last_value: row['last_value'].to_i,
            consumers: []
          }

          entry[:consumers] << {
            schema: row['table_schema'],
            table: row['table_name'],
            column: row['col_name']
          }
        end
      end

      def include_sequence?(seq_name, qualified_name)
        return true unless only_sequences

        only_sequences.include?(seq_name) || only_sequences.include?(qualified_name)
      end

      # A sequence no table uses in a `nextval` default cannot be advanced from
      # table data. Operators must handle those manually, so make them visible.
      def warn_about_sequences_without_consumers(db_name, connection, sequences)
        return if only_sequences

        orphans = connection.select_values(ALL_SEQUENCES_SQL) - sequences.keys
        return if orphans.empty?

        logger.warn(build_structured_payload_labkit(
          message: 'Sequences without consumer tables were not synced',
          database: db_name.to_s,
          sequences: orphans
        ))
        puts Rainbow("  #{db_name}: skipped #{orphans.size} sequence(s) with no consumer " \
          "tables: #{orphans.join(', ')}").yellow
      end

      def warn_about_unresolved_defaults(db_name, connection)
        return if only_sequences

        unresolved = connection.select_values(UNRESOLVED_NEXTVAL_DEFAULTS_SQL)
        return if unresolved.empty?

        logger.warn(build_structured_payload_labkit(
          message: 'Columns with unresolvable nextval defaults were not considered',
          database: db_name.to_s,
          columns: unresolved
        ))
        puts Rainbow("  #{db_name}: could not resolve the sequence behind #{unresolved.size} " \
          "column default(s): #{unresolved.join(', ')}").yellow
      end

      # @return [Boolean] true when the sequence was advanced
      def sync_single_sequence(db_name, connection, seq_name, seq_info)
        max_value = seq_info[:consumers].filter_map do |consumer|
          table_name = quote_qualified_name(connection, consumer[:schema], consumer[:table])
          col_name = connection.quote_column_name(consumer[:column])

          connection.select_value("SELECT MAX(#{col_name}) FROM #{table_name}")
        end.max

        # All consumer tables are empty, or the data sits below the sequence's
        # reserved range (MINVALUE for organizations_id_seq, START WITH for
        # work_item_custom_types_id_seq). The sequence is already positioned
        # correctly; setval would raise or burn reserved IDs.
        return false if max_value.nil? || max_value < [seq_info[:seq_min], seq_info[:seq_start]].max

        if max_value > seq_info[:seq_max]
          raise SyncError, "Sequence #{seq_name} has rows above its MAXVALUE " \
            "(max #{max_value}, MAXVALUE #{seq_info[:seq_max]})"
        end

        target_value = max_value + SEQUENCE_BUFFER

        if target_value > seq_info[:seq_max]
          logger.warn(build_structured_payload_labkit(
            message: 'Sequence buffer clamped to MAXVALUE',
            database: db_name.to_s,
            sequence: seq_name,
            max_value: max_value,
            seq_max: seq_info[:seq_max]
          ))
          target_value = seq_info[:seq_max]
        end

        return false if target_value <= seq_info[:last_value]

        quoted_seq = connection.quote(quote_qualified_name(connection, seq_info[:seq_schema], seq_info[:seq_name]))

        # Re-read the current position inside the statement so a sequence that
        # advanced after discovery is never moved backwards.
        connection.select_value(
          "SELECT setval(#{quoted_seq}, GREATEST(#{target_value}, " \
            "COALESCE(pg_sequence_last_value(#{quoted_seq}::regclass), 0)))"
        )

        logger.info(build_structured_payload_labkit(
          message: 'Sequence updated',
          database: db_name.to_s,
          sequence: seq_name,
          previous_value: seq_info[:last_value],
          new_value: target_value
        ))

        true
      end

      # Quotes schema and relation separately so identifiers containing dots
      # or uppercase cannot be mis-parsed; quote_column_name never splits.
      def quote_qualified_name(connection, schema, name)
        "#{connection.quote_column_name(schema)}.#{connection.quote_column_name(name)}"
      end
    end
    # rubocop:enable Rails/Output
  end
end
