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

      # Live snapshot of in-progress (auto)vacuums for the current database.
      # relid is resolved to schema.table via pg_class/pg_namespace, and the
      # result is scoped to the current database (the view reports for the
      # whole cluster) via the view's own datname.
      #
      # The %{activity_columns}/%{activity_join} placeholders join
      # pg_stat_activity to classify each vacuum: backend_type separates
      # autovacuum workers from manual VACUUM, the query text reveals
      # anti-wraparound runs, and query_start gives the elapsed running time
      # (computed server-side so the value does not depend on the browser
      # clock). A restricted role (e.g. one without pg_monitor) may be denied
      # pg_stat_activity, so those placeholders are dropped in that case and the
      # core progress columns are still returned. The %{delay_time_column}
      # placeholder is filled in only on PostgreSQL 18+ (see
      # DELAY_TIME_MINIMUM_VERSION).
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
          v.indexes_processed
          %{activity_columns}
          %{delay_time_column}
        FROM pg_stat_progress_vacuum v
        JOIN pg_class c ON c.oid = v.relid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        %{activity_join}
        WHERE v.datname = current_database()
        ORDER BY v.pid
      SQL

      ACTIVITY_COLUMNS = <<~SQL.chomp
        , a.backend_type,
          a.query AS activity_query,
          EXTRACT(EPOCH FROM (clock_timestamp() - a.query_start))::bigint AS running_time_seconds
      SQL

      ACTIVITY_JOIN = 'LEFT JOIN pg_stat_activity a ON a.pid = v.pid'

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
          .merge(collect_vacuum_section(connection))
          .merge(autovacuum_config: collect_autovacuum_config(connection))
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, database_name: database_name)
        { error: "Failed to gather information for database: #{database_name}" }
      end

      # Vacuum section of the payload: the in-progress vacuum list plus a flag
      # telling the frontend whether pg_stat_activity was readable. The full
      # query joins pg_stat_activity for the classification/runtime columns; a
      # restricted role (e.g. one without pg_monitor) is denied that view, so we
      # retry without the join and report activity as unavailable rather than
      # failing the whole diagnostics payload.
      def collect_vacuum_section(connection)
        return { vacuums: [], vacuum_activity_available: true } if
          connection.database_version < VACUUM_PROGRESS_MINIMUM_VERSION

        vacuums(connection, activity_available: activity_readable?(connection))
      rescue ActiveRecord::StatementInvalid => e
        # Belt and braces: if SELECT on the view is revoked outright (as on
        # GitLab.com) the join is denied even when activity_readable? is true,
        # so degrade instead of failing the whole payload.
        raise unless e.cause.is_a?(PG::InsufficientPrivilege)

        vacuums(connection, activity_available: false)
      end

      # pg_stat_activity only shows another backend's backend_type, query, and
      # query_start to a role that can read all stats; for everyone else those
      # columns are null on other backends. An autovacuum worker runs under a
      # different backend, so without this privilege we would misclassify it as
      # a manual VACUUM and miss anti-wraparound and running time. Skip the join
      # in that case and report activity as unavailable. Superusers and members
      # of pg_read_all_stats (which pg_monitor includes) see everything.
      def activity_readable?(connection)
        ActiveModel::Type::Boolean.new.cast(
          connection.select_value(
            "SELECT current_setting('is_superuser')::boolean " \
              "OR pg_has_role(current_user, 'pg_read_all_stats', 'MEMBER')"
          )
        )
      end

      # Reads are routed to the primary because autovacuum only runs there; a
      # replica would report an empty progress view. Byte/count columns are
      # returned as integers and delay_time (PostgreSQL 18+) as a float or nil.
      # The activity-derived fields are nil when pg_stat_activity is unavailable.
      def vacuums(connection, activity_available:)
        sql = format(
          VACUUM_PROGRESS_SQL,
          activity_columns: activity_available ? ACTIVITY_COLUMNS : '',
          activity_join: activity_available ? ACTIVITY_JOIN : '',
          delay_time_column: delay_time_column(connection)
        )

        rows = Gitlab::Database::LoadBalancing::SessionMap
          .current(connection.load_balancer)
          .use_primary { connection.select_all(sql) }

        list = rows.map do |row|
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
            vacuum_type: activity_available ? vacuum_type(row) : nil,
            anti_wraparound: activity_available ? anti_wraparound?(row) : nil,
            running_time_seconds: activity_available ? row['running_time_seconds']&.to_i : nil,
            delay_time: row['delay_time']&.to_f
          }
        end

        { vacuums: list, vacuum_activity_available: activity_available }
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

      # Settings are read on the primary so the report matches the database
      # autovacuum actually runs on; a replica can carry different GUC values.
      def collect_autovacuum_config(connection)
        Gitlab::Database::LoadBalancing::SessionMap
          .current(connection.load_balancer)
          .use_primary do
            Diagnostics::Checks::AutovacuumSettings.new(connection).execute
          end
      end
    end
  end
end
