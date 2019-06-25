# frozen_string_literal: true

module Gitlab
  module Database
    # The max value of INTEGER type is the same between MySQL and PostgreSQL:
    # https://www.postgresql.org/docs/9.2/static/datatype-numeric.html
    # http://dev.mysql.com/doc/refman/5.7/en/integer-types.html
    MAX_INT_VALUE = 2147483647
    # The max value between MySQL's TIMESTAMP and PostgreSQL's timestampz:
    # https://www.postgresql.org/docs/9.1/static/datatype-datetime.html
    # https://dev.mysql.com/doc/refman/5.7/en/datetime.html
    MAX_TIMESTAMP_VALUE = Time.at((1 << 31) - 1).freeze

    def self.config
      ActiveRecord::Base.configurations[Rails.env]
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
      postgresql? ? 'PostgreSQL' : 'MySQL'
    end

    def self.mysql?
      adapter_name.casecmp('mysql2').zero?
    end

    def self.postgresql?
      adapter_name.casecmp('postgresql').zero?
    end

    def self.read_only?
      false
    end

    def self.read_write?
      !self.read_only?
    end

    # Check whether the underlying database is in read-only mode
    def self.db_read_only?
      if postgresql?
        pg_is_in_recovery =
          ActiveRecord::Base.connection.execute('SELECT pg_is_in_recovery()')
            .first.fetch('pg_is_in_recovery')

        Gitlab::Utils.to_boolean(pg_is_in_recovery)
      else
        false
      end
    end

    def self.db_read_write?
      !self.db_read_only?
    end

    def self.version
      @version ||= database_version.match(/\A(?:PostgreSQL |)([^\s]+).*\z/)[1]
    end

    def self.postgresql_9_or_less?
      postgresql? && version.to_f < 10
    end

    def self.join_lateral_supported?
      postgresql? && version.to_f >= 9.3
    end

    def self.replication_slots_supported?
      postgresql? && version.to_f >= 9.4
    end

    def self.postgresql_minimum_supported_version?
      postgresql? && version.to_f >= 9.6
    end

    # map some of the function names that changed between PostgreSQL 9 and 10
    # https://wiki.postgresql.org/wiki/New_in_postgres_10
    def self.pg_wal_lsn_diff
      Gitlab::Database.postgresql_9_or_less? ? 'pg_xlog_location_diff' : 'pg_wal_lsn_diff'
    end

    def self.pg_current_wal_insert_lsn
      Gitlab::Database.postgresql_9_or_less? ? 'pg_current_xlog_insert_location' : 'pg_current_wal_insert_lsn'
    end

    def self.pg_last_wal_receive_lsn
      Gitlab::Database.postgresql_9_or_less? ? 'pg_last_xlog_receive_location' : 'pg_last_wal_receive_lsn'
    end

    def self.pg_last_wal_replay_lsn
      Gitlab::Database.postgresql_9_or_less? ? 'pg_last_xlog_replay_location' : 'pg_last_wal_replay_lsn'
    end

    def self.pg_last_xact_replay_timestamp
      'pg_last_xact_replay_timestamp'
    end

    def self.nulls_last_order(field, direction = 'ASC')
      order = "#{field} #{direction}"

      if postgresql?
        order = "#{order} NULLS LAST"
      else
        # `field IS NULL` will be `0` for non-NULL columns and `1` for NULL
        # columns. In the (default) ascending order, `0` comes first.
        order = "#{field} IS NULL, #{order}" if direction == 'ASC'
      end

      order
    end

    def self.nulls_first_order(field, direction = 'ASC')
      order = "#{field} #{direction}"

      if postgresql?
        order = "#{order} NULLS FIRST"
      else
        # `field IS NULL` will be `0` for non-NULL columns and `1` for NULL
        # columns. In the (default) ascending order, `0` comes first.
        order = "#{field} IS NULL, #{order}" if direction == 'DESC'
      end

      order
    end

    def self.random
      postgresql? ? "RANDOM()" : "RAND()"
    end

    def self.true_value
      if postgresql?
        "'t'"
      else
        1
      end
    end

    def self.false_value
      if postgresql?
        "'f'"
      else
        0
      end
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
    #              the inserted rows, this only works on PostgreSQL.
    # disable_quote - A key or an Array of keys to exclude from quoting (You
    #                 become responsible for protection from SQL injection for
    #                 these keys!)
    def self.bulk_insert(table, rows, return_ids: false, disable_quote: [])
      return if rows.empty?

      keys = rows.first.keys
      columns = keys.map { |key| connection.quote_column_name(key) }
      return_ids = false if mysql?

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

      if return_ids
        sql = "#{sql}RETURNING id"
      end

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
    def self.create_connection_pool(pool_size, host = nil)
      # See activerecord-4.2.7.1/lib/active_record/connection_adapters/connection_specification.rb
      env = Rails.env
      original_config = ActiveRecord::Base.configurations

      env_config = original_config[env].merge('pool' => pool_size)
      env_config['host'] = host if host

      config = original_config.merge(env => env_config)

      spec =
        ActiveRecord::
          ConnectionAdapters::
          ConnectionSpecification::Resolver.new(config).spec(env.to_sym)

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    private_class_method :connection

    def self.cached_column_exists?(table_name, column_name)
      connection.schema_cache.columns_hash(table_name).has_key?(column_name.to_s)
    end

    def self.cached_table_exists?(table_name)
      connection.schema_cache.data_source_exists?(table_name)
    end

    def self.database_version
      row = connection.execute("SELECT VERSION()").first

      if postgresql?
        row['version']
      else
        row.first
      end
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

    # inside_transaction? will return true if the caller is running within a transaction. Handles special cases
    # when running inside a test environment, in which the entire test is running with a DatabaseCleaner transaction
    def self.inside_transaction?
      ActiveRecord::Base.connection.open_transactions > open_transactions_baseline
    end

    def self.open_transactions_baseline
      if ::Rails.env.test?
        return DatabaseCleaner.connections.count { |conn| conn.strategy.is_a?(DatabaseCleaner::ActiveRecord::Transaction) }
      end

      0
    end
    private_class_method :open_transactions_baseline
  end
end
