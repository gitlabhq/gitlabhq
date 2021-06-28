# frozen_string_literal: true

module Gitlab
  module Database
    CI_DATABASE_NAME = 'ci'

    # This constant is used when renaming tables concurrently.
    # If you plan to rename a table using the `rename_table_safely` method, add your table here one milestone before the rename.
    # Example:
    # TABLES_TO_BE_RENAMED = {
    #   'old_name' => 'new_name'
    # }.freeze
    TABLES_TO_BE_RENAMED = {
      'services' => 'integrations'
    }.freeze

    # Minimum PostgreSQL version requirement per documentation:
    # https://docs.gitlab.com/ee/install/requirements.html#postgresql-requirements
    MINIMUM_POSTGRES_VERSION = 12

    # https://www.postgresql.org/docs/9.2/static/datatype-numeric.html
    MAX_INT_VALUE = 2147483647
    MIN_INT_VALUE = -2147483648

    # The max value between MySQL's TIMESTAMP and PostgreSQL's timestampz:
    # https://www.postgresql.org/docs/9.1/static/datatype-datetime.html
    # https://dev.mysql.com/doc/refman/5.7/en/datetime.html
    # FIXME: this should just be the max value of timestampz
    MAX_TIMESTAMP_VALUE = Time.at((1 << 31) - 1).freeze

    # The maximum number of characters for text fields, to avoid DoS attacks via parsing huge text fields
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/61974
    MAX_TEXT_SIZE_LIMIT = 1_000_000

    # Minimum schema version from which migrations are supported
    # Migrations before this version may have been removed
    MIN_SCHEMA_VERSION = 20190506135400
    MIN_SCHEMA_GITLAB_VERSION = '11.11.0'

    # Schema we store dynamically managed partitions in (e.g. for time partitioning)
    DYNAMIC_PARTITIONS_SCHEMA = :gitlab_partitions_dynamic

    # Schema we store static partitions in (e.g. for hash partitioning)
    STATIC_PARTITIONS_SCHEMA = :gitlab_partitions_static

    # This is an extensive list of postgres schemas owned by GitLab
    # It does not include the default public schema
    EXTRA_SCHEMAS = [DYNAMIC_PARTITIONS_SCHEMA, STATIC_PARTITIONS_SCHEMA].freeze

    DEFAULT_POOL_HEADROOM = 10

    # We configure the database connection pool size automatically based on the
    # configured concurrency. We also add some headroom, to make sure we don't run
    # out of connections when more threads besides the 'user-facing' ones are
    # running.
    #
    # Read more about this in doc/development/database/client_side_connection_pool.md
    def self.default_pool_size
      headroom = (ENV["DB_POOL_HEADROOM"].presence || DEFAULT_POOL_HEADROOM).to_i

      Gitlab::Runtime.max_threads + headroom
    end

    def self.config
      default_config_hash = ActiveRecord::Base.configurations.find_db_config(Rails.env)&.configuration_hash || {}

      default_config_hash.with_indifferent_access.tap do |hash|
        # Match config/initializers/database_config.rb
        hash[:pool] ||= default_pool_size
      end
    end

    def self.has_config?(database_name)
      Gitlab::Application.config.database_configuration[Rails.env].include?(database_name.to_s)
    end

    def self.ci_database?(name)
      name == CI_DATABASE_NAME
    end

    def self.username
      config['username'] || ENV['USER']
    end

    def self.database_name
      config['database']
    end

    def self.adapter_name
      config['adapter']
    end

    def self.human_adapter_name
      if postgresql?
        'PostgreSQL'
      else
        'Unknown'
      end
    end

    # Disables prepared statements for the current database connection.
    def self.disable_prepared_statements
      ActiveRecord::Base.establish_connection(config.merge(prepared_statements: false))
    end

    # @deprecated
    def self.postgresql?
      adapter_name.casecmp('postgresql') == 0
    end

    def self.read_only?
      false
    end

    def self.read_write?
      !self.read_only?
    end

    # Check whether the underlying database is in read-only mode
    def self.db_read_only?
      pg_is_in_recovery =
        ActiveRecord::Base
          .connection
          .execute('SELECT pg_is_in_recovery()')
          .first
          .fetch('pg_is_in_recovery')

      Gitlab::Utils.to_boolean(pg_is_in_recovery)
    end

    def self.db_read_write?
      !self.db_read_only?
    end

    def self.version
      @version ||= database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
    end

    def self.postgresql_minimum_supported_version?
      version.to_f >= MINIMUM_POSTGRES_VERSION
    end

    def self.check_postgres_version_and_print_warning
      return if Gitlab::Database.postgresql_minimum_supported_version?
      return if Gitlab::Runtime.rails_runner?

      Kernel.warn ERB.new(Rainbow.new.wrap(<<~EOS).red).result

                  ██     ██  █████  ██████  ███    ██ ██ ███    ██  ██████ 
                  ██     ██ ██   ██ ██   ██ ████   ██ ██ ████   ██ ██      
                  ██  █  ██ ███████ ██████  ██ ██  ██ ██ ██ ██  ██ ██   ███ 
                  ██ ███ ██ ██   ██ ██   ██ ██  ██ ██ ██ ██  ██ ██ ██    ██ 
                   ███ ███  ██   ██ ██   ██ ██   ████ ██ ██   ████  ██████  

        ******************************************************************************
          You are using PostgreSQL <%= Gitlab::Database.version %>, but PostgreSQL >= <%= Gitlab::Database::MINIMUM_POSTGRES_VERSION %>
          is required for this version of GitLab.
          <% if Rails.env.development? || Rails.env.test? %>
          If using gitlab-development-kit, please find the relevant steps here:
            https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/postgresql.md#upgrade-postgresql
          <% end %>
          Please upgrade your environment to a supported PostgreSQL version, see
          https://docs.gitlab.com/ee/install/requirements.html#database for details.
        ******************************************************************************
      EOS
    rescue ActiveRecord::ActiveRecordError, PG::Error
      # ignore - happens when Rake tasks yet have to create a database, e.g. for testing
    end

    def self.nulls_order(field, direction = :asc, nulls_order = :nulls_last)
      raise ArgumentError unless [:nulls_last, :nulls_first].include?(nulls_order)
      raise ArgumentError unless [:asc, :desc].include?(direction)

      case nulls_order
      when :nulls_last then nulls_last_order(field, direction)
      when :nulls_first then nulls_first_order(field, direction)
      end
    end

    def self.nulls_last_order(field, direction = 'ASC')
      Arel.sql("#{field} #{direction} NULLS LAST")
    end

    def self.nulls_first_order(field, direction = 'ASC')
      Arel.sql("#{field} #{direction} NULLS FIRST")
    end

    def self.random
      "RANDOM()"
    end

    def self.true_value
      "'t'"
    end

    def self.false_value
      "'f'"
    end

    def self.with_connection_pool(pool_size)
      pool = create_connection_pool(pool_size)

      begin
        yield(pool)
      ensure
        pool.disconnect!
      end
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
    def self.bulk_insert(table, rows, return_ids: false, disable_quote: [], on_conflict: nil)
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

    def self.sanitize_timestamp(timestamp)
      MAX_TIMESTAMP_VALUE > timestamp ? timestamp : MAX_TIMESTAMP_VALUE.dup
    end

    # pool_size - The size of the DB pool.
    # host - An optional host name to use instead of the default one.
    def self.create_connection_pool(pool_size, host = nil, port = nil)
      original_config = Gitlab::Database.config

      env_config = original_config.merge(pool: pool_size)
      env_config[:host] = host if host
      env_config[:port] = port if port

      ActiveRecord::ConnectionAdapters::ConnectionHandler.new.establish_connection(env_config)
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    private_class_method :connection

    def self.cached_column_exists?(table_name, column_name)
      connection.schema_cache.columns_hash(table_name).has_key?(column_name.to_s)
    end

    def self.cached_table_exists?(table_name)
      exists? && connection.schema_cache.data_source_exists?(table_name)
    end

    def self.database_version
      row = connection.execute("SELECT VERSION()").first

      row['version']
    end

    def self.exists?
      connection

      true
    rescue StandardError
      false
    end

    def self.system_id
      row = connection.execute('SELECT system_identifier FROM pg_control_system()').first

      row['system_identifier']
    end

    # @param [ActiveRecord::Connection] ar_connection
    # @return [String]
    def self.get_write_location(ar_connection)
      use_new_load_balancer_query = Gitlab::Utils.to_boolean(ENV['USE_NEW_LOAD_BALANCER_QUERY'], default: true)

      sql = if use_new_load_balancer_query
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

    private_class_method :database_version

    def self.add_post_migrate_path_to_rails(force: false)
      return if ENV['SKIP_POST_DEPLOYMENT_MIGRATIONS'] && !force

      Rails.application.config.paths['db'].each do |db_path|
        path = Rails.root.join(db_path, 'post_migrate').to_s

        unless Rails.application.config.paths['db/migrate'].include? path
          Rails.application.config.paths['db/migrate'] << path

          # Rails memoizes migrations at certain points where it won't read the above
          # path just yet. As such we must also update the following list of paths.
          ActiveRecord::Migrator.migrations_paths << path
        end
      end
    end

    def self.dbname(ar_connection)
      if ar_connection.respond_to?(:pool) &&
          ar_connection.pool.respond_to?(:db_config) &&
          ar_connection.pool.db_config.respond_to?(:database)
        return ar_connection.pool.db_config.database
      end

      'unknown'
    end

    # inside_transaction? will return true if the caller is running within a transaction. Handles special cases
    # when running inside a test environment, where tests may be wrapped in transactions
    def self.inside_transaction?
      if Rails.env.test?
        ActiveRecord::Base.connection.open_transactions > open_transactions_baseline
      else
        ActiveRecord::Base.connection.open_transactions > 0
      end
    end

    # These methods that access @open_transactions_baseline are not thread-safe.
    # These are fine though because we only call these in RSpec's main thread. If we decide to run
    # specs multi-threaded, we would need to use something like ThreadGroup to keep track of this value
    def self.set_open_transactions_baseline
      @open_transactions_baseline = ActiveRecord::Base.connection.open_transactions
    end

    def self.reset_open_transactions_baseline
      @open_transactions_baseline = 0
    end

    def self.open_transactions_baseline
      @open_transactions_baseline ||= 0
    end
    private_class_method :open_transactions_baseline

    # Monkeypatch rails with upgraded database observability
    def self.install_monkey_patches
      ActiveRecord::Base.prepend(ActiveRecordBaseTransactionMetrics)
    end

    # MonkeyPatch for ActiveRecord::Base for adding observability
    module ActiveRecordBaseTransactionMetrics
      extend ActiveSupport::Concern

      class_methods do
        # A monkeypatch over ActiveRecord::Base.transaction.
        # It provides observability into transactional methods.
        def transaction(**options, &block)
          ActiveSupport::Notifications.instrument('transaction.active_record', { connection: connection }) do
            super(**options, &block)
          end
        end
      end
    end
  end
end

Gitlab::Database.prepend_mod_with('Gitlab::Database')
