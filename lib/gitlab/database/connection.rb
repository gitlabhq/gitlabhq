# frozen_string_literal: true

module Gitlab
  module Database
    # Configuration settings and methods for interacting with a PostgreSQL
    # database, with support for multiple databases.
    class Connection
      DEFAULT_POOL_HEADROOM = 10

      attr_reader :scope

      # Initializes a new `Database`.
      #
      # The `scope` argument must be an object (such as `ActiveRecord::Base`)
      # that supports retrieving connections and connection pools.
      def initialize(scope = ActiveRecord::Base)
        @config = nil
        @scope = scope
        @version = nil
        @open_transactions_baseline = 0
      end

      # We configure the database connection pool size automatically based on
      # the configured concurrency. We also add some headroom, to make sure we
      # don't run out of connections when more threads besides the 'user-facing'
      # ones are running.
      #
      # Read more about this in
      # doc/development/database/client_side_connection_pool.md
      def default_pool_size
        headroom =
          (ENV["DB_POOL_HEADROOM"].presence || DEFAULT_POOL_HEADROOM).to_i

        Gitlab::Runtime.max_threads + headroom
      end

      def config
        # The result of this method must not be cached, as other methods may use
        # it after making configuration changes and expect those changes to be
        # present. For example, `disable_prepared_statements` expects the
        # configuration settings to always be up to date.
        #
        # See the following for more information:
        #
        # - https://gitlab.com/gitlab-org/release/retrospectives/-/issues/39
        # - https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5238
        scope.connection_db_config.configuration_hash.with_indifferent_access
      end

      def pool_size
        config[:pool] || default_pool_size
      end

      def username
        config[:username] || ENV['USER']
      end

      def database_name
        config[:database]
      end

      def adapter_name
        config[:adapter]
      end

      def human_adapter_name
        if postgresql?
          'PostgreSQL'
        else
          'Unknown'
        end
      end

      def postgresql?
        adapter_name.casecmp('postgresql') == 0
      end

      def db_config_with_default_pool_size
        db_config_object = scope.connection_db_config
        config = db_config_object.configuration_hash.merge(pool: default_pool_size)

        ActiveRecord::DatabaseConfigurations::HashConfig.new(
          db_config_object.env_name,
          db_config_object.name,
          config
        )
      end

      # Disables prepared statements for the current database connection.
      def disable_prepared_statements
        scope.establish_connection(config.merge(prepared_statements: false))
      end

      # Check whether the underlying database is in read-only mode
      def db_read_only?
        pg_is_in_recovery =
          scope
            .connection
            .execute('SELECT pg_is_in_recovery()')
            .first
            .fetch('pg_is_in_recovery')

        Gitlab::Utils.to_boolean(pg_is_in_recovery)
      end

      def db_read_write?
        !db_read_only?
      end

      def version
        @version ||= database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
      end

      def database_version
        connection.execute("SELECT VERSION()").first['version']
      end

      def postgresql_minimum_supported_version?
        version.to_f >= MINIMUM_POSTGRES_VERSION
      end

      # Bulk inserts a number of rows into a table, optionally returning their
      # IDs.
      #
      # table - The name of the table to insert the rows into.
      # rows - An Array of Hash instances, each mapping the columns to their
      #        values.
      # return_ids - When set to true the return value will be an Array of IDs of
      #              the inserted rows
      # disable_quote - A key or an Array of keys to exclude from quoting (You
      #                 become responsible for protection from SQL injection for
      #                 these keys!)
      # on_conflict - Defines an upsert. Values can be: :disabled (default) or
      #               :do_nothing
      def bulk_insert(table, rows, return_ids: false, disable_quote: [], on_conflict: nil)
        return if rows.empty?

        keys = rows.first.keys
        columns = keys.map { |key| connection.quote_column_name(key) }

        disable_quote = Array(disable_quote).to_set
        tuples = rows.map do |row|
          keys.map do |k|
            disable_quote.include?(k) ? row[k] : connection.quote(row[k])
          end
        end

        sql = <<-EOF
          INSERT INTO #{table} (#{columns.join(', ')})
          VALUES #{tuples.map { |tuple| "(#{tuple.join(', ')})" }.join(', ')}
        EOF

        sql = "#{sql} ON CONFLICT DO NOTHING" if on_conflict == :do_nothing

        sql = "#{sql} RETURNING id" if return_ids

        result = connection.execute(sql)

        if return_ids
          result.values.map { |tuple| tuple[0].to_i }
        else
          []
        end
      end

      def cached_column_exists?(table_name, column_name)
        connection
          .schema_cache.columns_hash(table_name)
          .has_key?(column_name.to_s)
      end

      def cached_table_exists?(table_name)
        exists? && connection.schema_cache.data_source_exists?(table_name)
      end

      def exists?
        connection

        true
      rescue StandardError
        false
      end

      def system_id
        row = connection
          .execute('SELECT system_identifier FROM pg_control_system()')
          .first

        row['system_identifier']
      end

      # @param [ActiveRecord::Connection] ar_connection
      # @return [String]
      def get_write_location(ar_connection)
        use_new_load_balancer_query = Gitlab::Utils
          .to_boolean(ENV['USE_NEW_LOAD_BALANCER_QUERY'], default: true)

        sql =
          if use_new_load_balancer_query
            <<~NEWSQL
              SELECT CASE
                  WHEN pg_is_in_recovery() = true AND EXISTS (SELECT 1 FROM pg_stat_get_wal_senders())
                    THEN pg_last_wal_replay_lsn()::text
                  WHEN pg_is_in_recovery() = false
                    THEN pg_current_wal_insert_lsn()::text
                    ELSE NULL
                  END AS location;
            NEWSQL
          else
            <<~SQL
              SELECT pg_current_wal_insert_lsn()::text AS location
            SQL
          end

        row = ar_connection.select_all(sql).first
        row['location'] if row
      end

      # inside_transaction? will return true if the caller is running within a
      # transaction. Handles special cases when running inside a test
      # environment, where tests may be wrapped in transactions
      def inside_transaction?
        base = Rails.env.test? ? @open_transactions_baseline : 0

        scope.connection.open_transactions > base
      end

      # These methods that access @open_transactions_baseline are not
      # thread-safe.  These are fine though because we only call these in
      # RSpec's main thread. If we decide to run specs multi-threaded, we would
      # need to use something like ThreadGroup to keep track of this value
      def set_open_transactions_baseline
        @open_transactions_baseline = scope.connection.open_transactions
      end

      def reset_open_transactions_baseline
        @open_transactions_baseline = 0
      end

      private

      def connection
        scope.connection
      end
    end
  end
end

Gitlab::Database::Connection.prepend_mod_with('Gitlab::Database::Connection')
