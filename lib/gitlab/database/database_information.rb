# frozen_string_literal: true

module Gitlab
  module Database
    # Collects a read-only PostgreSQL state snapshot for the
    # "Database information" panel on /admin/database_diagnostics.
    class DatabaseInformation
      DEFAULT_DATABASE_NAMES = %w[main].freeze

      USER_TOKEN = '$user'

      # pg_stat_progress_vacuum gained delay_time in PostgreSQL 18. All other
      # columns we read are present from PostgreSQL 17 (our minimum version),
      # so this is the only column that needs version gating.
      DELAY_TIME_MINIMUM_VERSION = 18_00_00

      # An autovacuum triggered to prevent transaction ID (or multixact)
      # wraparound is reported by PostgreSQL with this marker appended to the
      # query text in pg_stat_activity. Such a vacuum is non-cancellable and
      # must not be killed casually, so we flag it explicitly.
      ANTI_WRAPAROUND_MARKER = 'to prevent wraparound'

      SCHEMAS_SQL = <<~SQL
        SELECT n.nspname AS name,
          (n.nspname = current_schema()) AS is_current,
          pg_catalog.pg_get_userbyid(n.nspowner) AS owner,
          EXISTS (
            SELECT 1 FROM pg_catalog.pg_class c
            WHERE c.relnamespace = n.oid AND c.relkind IN ('r', 'p', 'S')
          ) AS has_tables
        FROM pg_catalog.pg_namespace n
        WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
        ORDER BY is_current DESC, name ASC
      SQL

      # Live snapshot of in-progress (auto)vacuums for the current database.
      # relid is resolved to schema.table via pg_class/pg_namespace, and the
      # result is scoped to the current database (the view reports for the
      # whole cluster) via the view's own datname. Joining pg_stat_activity
      # classifies each vacuum:
      # backend_type separates autovacuum workers from manual VACUUM, the
      # query text reveals anti-wraparound runs, and query_start gives the
      # elapsed running time (computed server-side so the value does not depend
      # on the browser clock). The %{delay_time_column} placeholder is filled
      # in only on PostgreSQL 18+ (see DELAY_TIME_MINIMUM_VERSION).
      VACUUM_PROGRESS_SQL = <<~SQL
        SELECT v.pid,
          n.nspname AS schema_name,
          c.relname AS table_name,
          v.phase,
          v.heap_blks_total,
          v.heap_blks_scanned,
          v.heap_blks_vacuumed,
          v.index_vacuum_count,
          v.max_dead_tuple_bytes,
          v.dead_tuple_bytes,
          v.indexes_total,
          v.indexes_processed,
          a.backend_type,
          a.query AS activity_query,
          EXTRACT(EPOCH FROM (clock_timestamp() - a.query_start))::bigint AS running_time_seconds
          %{delay_time_column}
        FROM pg_stat_progress_vacuum v
        JOIN pg_class c ON c.oid = v.relid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        LEFT JOIN pg_stat_activity a ON a.pid = v.pid
        WHERE v.datname = current_database()
        ORDER BY v.pid
      SQL

      def self.execute(database_names: DEFAULT_DATABASE_NAMES)
        new(database_names: database_names).execute
      end

      def initialize(database_names: DEFAULT_DATABASE_NAMES)
        @database_names = database_names
      end

      def execute
        {
          databases: @database_names.index_with { |name| collect_for_database(name) }
        }
      end

      private

      def collect_for_database(database_name)
        model = Gitlab::Database.database_base_models[database_name]
        return { error: "Unknown database: #{database_name}" } unless model

        connection = model.connection

        search_path = connection.select_value('SHOW search_path').to_s
        schemas = connection.select_all(SCHEMAS_SQL).map do |row|
          {
            name: row['name'],
            current: ActiveModel::Type::Boolean.new.cast(row['is_current']),
            owner: row['owner'],
            has_tables: ActiveModel::Type::Boolean.new.cast(row['has_tables'])
          }
        end

        current_user = connection.select_value('SELECT current_user').to_s

        {
          current_user: current_user,
          search_path: search_path,
          schemas: schemas,
          findings: search_path_findings(search_path, schemas, current_user),
          vacuums: collect_vacuums(connection)
        }
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
      end

      # Inspects the live search_path against GitLab's PostgreSQL conventions
      # and returns an ordered list of findings. Each finding is a plain hash:
      # { severity: 'error'|'warning', code: String, message: String }.
      def search_path_findings(search_path, schemas, current_user)
        entries = parse_search_path(search_path)
        partition_schema_names = Gitlab::Database::EXTRA_SCHEMAS.map(&:to_s)

        findings = []

        if (entries & partition_schema_names).any?
          findings << {
            severity: 'warning',
            code: 'search_path_contains_partition_schema',
            message: s_('DatabaseDiagnostics|The search path contains a GitLab partition schema. ' \
              'Partition schemas are expected to be referenced fully qualified, not via the search path.')
          }
        end

        # Resolve the "$user" token to the connected role so a user-named schema
        # is considered, and drop partition schemas (covered above). What remains
        # are the candidate schemas the search path resolves objects against.
        candidate_names = entries.map { |entry| entry == USER_TOKEN ? current_user : entry } -
          partition_schema_names
        populated = schemas.select do |schema|
          candidate_names.include?(schema[:name]) && schema[:has_tables]
        end

        if populated.size > 1
          findings << {
            severity: 'warning',
            code: 'search_path_objects_split_across_schemas',
            message: format(
              s_('DatabaseDiagnostics|More than one schema in the search path contains objects: %{schemas}. ' \
                'GitLab\'s objects should all live in a single schema. If they are split across ' \
                'multiple schemas, unqualified references can resolve unexpectedly.'),
              schemas: populated.pluck(:name).join(', ')
            )
          }
        end

        findings
      end

      # Normalizes a raw search_path string into an ordered list of tokens,
      # stripping whitespace and surrounding double quotes while preserving
      # the "$user" token.
      def parse_search_path(search_path)
        search_path.split(',').map do |entry|
          entry.strip.delete_prefix('"').delete_suffix('"')
        end
      end

      # Returns an ordered list of in-progress vacuums as plain hashes. Reads
      # are routed to the primary because autovacuum only runs there; a replica
      # would report an empty progress view. Byte/count columns are returned as
      # integers and delay_time (PostgreSQL 18+) as a float or nil.
      def collect_vacuums(connection)
        sql = format(VACUUM_PROGRESS_SQL, delay_time_column: delay_time_column(connection))

        rows = Gitlab::Database::LoadBalancing::SessionMap
          .current(connection.load_balancer)
          .use_primary { connection.select_all(sql) }

        rows.map do |row|
          {
            pid: row['pid'].to_i,
            schema_name: row['schema_name'],
            table_name: row['table_name'],
            phase: row['phase'],
            heap_blks_total: row['heap_blks_total'].to_i,
            heap_blks_scanned: row['heap_blks_scanned'].to_i,
            heap_blks_vacuumed: row['heap_blks_vacuumed'].to_i,
            index_vacuum_count: row['index_vacuum_count'].to_i,
            max_dead_tuple_bytes: row['max_dead_tuple_bytes'].to_i,
            dead_tuple_bytes: row['dead_tuple_bytes'].to_i,
            indexes_total: row['indexes_total'].to_i,
            indexes_processed: row['indexes_processed'].to_i,
            vacuum_type: vacuum_type(row),
            anti_wraparound: anti_wraparound?(row),
            running_time_seconds: row['running_time_seconds']&.to_i,
            delay_time: row['delay_time']&.to_f
          }
        end
      end

      # 'autovacuum worker' is the backend_type PostgreSQL reports for vacuums
      # launched by the autovacuum daemon; anything else (a client backend) is
      # a manually issued VACUUM.
      def vacuum_type(row)
        row['backend_type'] == 'autovacuum worker' ? 'autovacuum' : 'manual'
      end

      def anti_wraparound?(row)
        row['activity_query'].to_s.include?(ANTI_WRAPAROUND_MARKER)
      end

      def delay_time_column(connection)
        return '' if connection.database_version < DELAY_TIME_MINIMUM_VERSION

        ', v.delay_time'
      end
    end
  end
end
