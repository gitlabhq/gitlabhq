# frozen_string_literal: true

module Gitlab
  module Database
    # Collects a read-only PostgreSQL state snapshot for the
    # "Database information" panel on /admin/database_diagnostics.
    class DatabaseInformation
      DEFAULT_DATABASE_NAMES = %w[main].freeze

      USER_TOKEN = '$user'

      # pg_stat_progress_vacuum gained delay_time in PostgreSQL 18. All other
      # columns we read are present from PostgreSQL 17 (our minimum version).
      DELAY_TIME_MINIMUM_VERSION = 18_00_00

      # VACUUM_PROGRESS_SQL selects columns that only exist from PostgreSQL 17.
      # An instance mid-upgrade can still run an older version; skip vacuum
      # collection there instead of failing the whole diagnostics payload.
      VACUUM_PROGRESS_MINIMUM_VERSION = 17_00_00

      # An autovacuum triggered to prevent transaction ID (or multixact)
      # wraparound is reported by PostgreSQL with this marker appended to the
      # query text in pg_stat_activity. Such a vacuum is non-cancellable and
      # must not be killed casually, so we flag it explicitly.
      ANTI_WRAPAROUND_MARKER = 'to prevent wraparound'

      # Effective autovacuum-related GUCs to surface, read from pg_settings.
      # vacuum_cost_limit is included because autovacuum_vacuum_cost_limit may inherit it
      AUTOVACUUM_SETTING_NAMES = %w[
        autovacuum
        autovacuum_max_workers
        autovacuum_naptime
        autovacuum_vacuum_scale_factor
        autovacuum_vacuum_threshold
        autovacuum_analyze_scale_factor
        autovacuum_analyze_threshold
        autovacuum_vacuum_insert_scale_factor
        autovacuum_vacuum_insert_threshold
        autovacuum_vacuum_cost_delay
        autovacuum_vacuum_cost_limit
        vacuum_cost_limit
        autovacuum_work_mem
        maintenance_work_mem
        autovacuum_freeze_max_age
        autovacuum_multixact_freeze_max_age
      ].freeze

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

      # Relation names per schema, matched against the database dictionary to tell GitLab's
      # own objects apart from unrelated ones. relkind r/p/v/m covers the object kinds the
      # dictionary catalogs: tables, partitioned tables, views and materialized views.
      # Sequences (S) have no entry of their own, so each resolves through pg_depend
      # (deptype 'a' for serial, 'i' for identity) to its owning table's name, or falls back
      # to its own name when unowned and stays unrecognized. DISTINCT drops the duplicate
      # row that a table and its own sequence produce.
      SCHEMA_TABLES_SQL = <<~SQL
        SELECT DISTINCT n.nspname AS schema_name,
          COALESCE(owner_table.relname, c.relname) AS table_name
        FROM pg_catalog.pg_namespace n
        JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
        LEFT JOIN pg_catalog.pg_depend d
          ON c.relkind = 'S' AND d.objid = c.oid
          AND d.classid = 'pg_class'::regclass AND d.refclassid = 'pg_class'::regclass
          AND d.deptype IN ('a', 'i')
        LEFT JOIN pg_catalog.pg_class owner_table ON owner_table.oid = d.refobjid
        WHERE n.nspname NOT IN ('pg_catalog', 'pg_toast', 'information_schema')
          AND c.relkind IN ('r', 'p', 'v', 'm', 'S')
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

      # Effective autovacuum-related settings for the current backend. unit is
      # returned alongside setting so the frontend can render memory/time values
      # with their configured unit (e.g. "65536 kB"). Row order is irrelevant
      # here: autovacuum_settings below re-orders the result to match
      # AUTOVACUUM_SETTING_NAMES, which is the order the frontend renders in.
      AUTOVACUUM_SETTINGS_SQL = <<~SQL
        SELECT name, setting, unit
        FROM pg_settings
        WHERE name IN (%{names})
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

        schema_tables = connection.select_all(SCHEMA_TABLES_SQL).map { |row| [row['schema_name'], row['table_name']] }

        current_user = connection.select_value('SELECT current_user').to_s

        {
          current_user: current_user,
          search_path: search_path,
          schemas: schemas,
          findings: search_path_findings(search_path, schemas, schema_tables, current_user),
          vacuums: collect_vacuums(connection),
          autovacuum_config: collect_autovacuum_config(connection)
        }
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
      end

      # Inspects the live search_path against GitLab's PostgreSQL conventions
      # and returns an ordered list of findings. Each finding is a plain hash:
      # { severity: 'error'|'warning', code: String, message: String }.
      def search_path_findings(search_path, schemas, schema_tables, current_user)
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
        candidates = schemas.select { |schema| candidate_names.include?(schema[:name]) }

        # More than one schema on the search path holds objects of any kind. On
        # its own this can be legitimate (an extension's schema, a DBA's own
        # tooling), so it is only a warning: unqualified references still resolve
        # against the first match, which is worth flagging but not a defect.
        populated = candidates.select { |schema| schema[:has_tables] }
        if populated.size > 1
          findings << {
            severity: 'warning',
            code: 'search_path_objects_split_across_schemas',
            message: format(
              s_('DatabaseDiagnostics|More than one schema in the search path contains objects: %{schemas}. ' \
                'This can be intentional, but unqualified references resolve against the first match, so ' \
                'objects spread across schemas can resolve unexpectedly.'),
              schemas: populated.pluck(:name).join(', ')
            )
          }
        end

        # More than one schema on the search path holds GitLab's own objects.
        # GitLab expects all of its objects in a single schema, so this is a real
        # misconfiguration rather than a possibility, and is reported as an error.
        gitlab_populated = candidates.select { |schema| schema_has_gitlab_objects?(schema[:name], schema_tables) }
        if gitlab_populated.size > 1
          findings << {
            severity: 'error',
            code: 'search_path_gitlab_objects_split_across_schemas',
            message: format(
              s_('DatabaseDiagnostics|More than one schema in the search path contains GitLab objects: ' \
                '%{schemas}. GitLab\'s objects should all live in a single schema. When they are split ' \
                'across multiple schemas, unqualified references can resolve unexpectedly.'),
              schemas: gitlab_populated.pluck(:name).join(', ')
            )
          }
        end

        # GitLab objects in a schema the search path never consults cannot be
        # resolved by unqualified references, so GitLab never uses them. They
        # are typically leftovers from a restore or a migration into the wrong
        # schema. Partition schemas are exempt: GitLab keeps partitions there
        # by design, outside the search path.
        outside_names = schemas.pluck(:name) - candidate_names - partition_schema_names
        gitlab_outside = outside_names.select { |name| schema_has_gitlab_objects?(name, schema_tables) }
        if gitlab_outside.any?
          findings << {
            severity: 'warning',
            code: 'gitlab_objects_outside_search_path',
            message: format(
              s_('DatabaseDiagnostics|Schemas outside the search path contain GitLab objects: %{schemas}. ' \
                'GitLab does not resolve unqualified references against these schemas, so these objects are ' \
                'never used. They may be leftovers from a restore or an earlier misconfiguration.'),
              schemas: gitlab_outside.join(', ')
            )
          }
        end

        findings
      end

      def schema_has_gitlab_objects?(schema_name, schema_tables)
        schema_tables.any? { |(namespace, table_name)| namespace == schema_name && gitlab_object?(table_name) }
      end

      def gitlab_object?(table_name)
        schema = Gitlab::Database::GitlabSchema.table_schema(table_name)
        schema.present? && schema != :gitlab_internal
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
        return [] if connection.database_version < VACUUM_PROGRESS_MINIMUM_VERSION

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

      # Read-only snapshot of the effective autovacuum configuration (global settings)
      def collect_autovacuum_config(connection)
        Gitlab::Database::LoadBalancing::SessionMap
          .current(connection.load_balancer)
          .use_primary do
            { settings: autovacuum_settings(connection) }
          end
      end

      def autovacuum_settings(connection)
        names = AUTOVACUUM_SETTING_NAMES.map { |name| connection.quote(name) }.join(', ')
        sql = format(AUTOVACUUM_SETTINGS_SQL, names: names)

        rows = connection.select_all(sql).each_with_object({}) do |row, settings|
          settings[row['name']] = { value: row['setting'], unit: row['unit'] }
        end

        # Re-key in AUTOVACUUM_SETTING_NAMES order so the frontend can render
        # settings by simply iterating the hash, without its own copy of the
        # name list. Settings absent on the running PostgreSQL version (rows
        # won't have them) are skipped.
        AUTOVACUUM_SETTING_NAMES.each_with_object({}) do |name, ordered|
          ordered[name] = rows[name] if rows[name]
        end
      end
    end
  end
end
