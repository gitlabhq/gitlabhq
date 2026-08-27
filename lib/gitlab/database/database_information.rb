# frozen_string_literal: true

module Gitlab
  module Database
    # Collects a read-only PostgreSQL state snapshot for the
    # "Database information" panel on /admin/database_diagnostics.
    class DatabaseInformation
      DEFAULT_DATABASE_NAMES = %w[main].freeze

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

        Diagnostics::Checks::SchemaResolution.new(connection).execute
          .merge(
            vacuums: collect_vacuums(connection),
            autovacuum_config: collect_autovacuum_config(connection)
          )
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
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
