module Gitlab
  module Geo
    class HealthCheck
      def self.perform_checks
        raise NotImplementedError.new('Geo is only compatible with PostgreSQL') unless Gitlab::Database.postgresql?

        return '' unless Gitlab::Geo.secondary?
        return 'The Geo database configuration file is missing.' unless Gitlab::Geo.geo_database_configured?
        return 'The Geo node has a database that is not configured for streaming replication with the primary node.' unless self.database_secondary?
        return 'The Geo node does not appear to be replicating the database from the primary node.' if Gitlab::Database.pg_stat_wal_receiver_supported? && !self.streaming_active?

        database_version  = self.get_database_version.to_i
        migration_version = self.get_migration_version.to_i

        if database_version != migration_version
          return "Current Geo database version (#{database_version}) does not match latest migration (#{migration_version}).\n"\
                 'You may have to run `gitlab-rake geo:db:migrate` as root on the secondary.'
        end

        return 'The Geo database is not configured to use Foreign Data Wrapper.' unless Gitlab::Geo::Fdw.enabled?

        unless Gitlab::Geo::Fdw.fdw_up_to_date?
          return "The Geo database has an outdated FDW remote schema.".tap do |output|
            output << " It contains #{Gitlab::Geo::Fdw.count_tables} of #{ActiveRecord::Schema.tables.count} expected tables." unless Gitlab::Geo::Fdw.count_tables_match?
          end
        end

        return ''
      rescue => e
        e.message
      end

      def self.db_migrate_path
        # Lazy initialisation so Rails.root will be defined
        @db_migrate_path ||= File.join(Rails.root, 'ee', 'db', 'geo', 'migrate')
      end

      def self.db_post_migrate_path
        # Lazy initialisation so Rails.root will be defined
        @db_post_migrate_path ||= File.join(Rails.root, 'ee', 'db', 'geo', 'post_migrate')
      end

      def self.get_database_version
        if defined?(ActiveRecord)
          connection = ::Geo::BaseRegistry.connection
          schema_migrations_table_name = ActiveRecord::Base.schema_migrations_table_name

          if connection.table_exists?(schema_migrations_table_name)
            connection.execute("SELECT MAX(version) AS version FROM #{schema_migrations_table_name}")
                      .first
                      .fetch('version')
          end
        end
      end

      def self.get_migration_version
        latest_migration = nil

        Dir[File.join(self.db_migrate_path, "[0-9]*_*.rb"), File.join(self.db_post_migrate_path, "[0-9]*_*.rb")].each do |f|
          timestamp = f.scan(/0*([0-9]+)_[_.a-zA-Z0-9]*.rb/).first.first rescue -1

          if latest_migration.nil? || timestamp.to_i > latest_migration.to_i
            latest_migration = timestamp
          end
        end

        latest_migration
      end

      def self.database_secondary?
        ActiveRecord::Base.connection.execute('SELECT pg_is_in_recovery()')
          .first
          .fetch('pg_is_in_recovery') == 't'
      end

      def self.db_replication_lag_seconds
        # Obtain the replication lag in seconds
        lag =
          ActiveRecord::Base.connection.execute(<<-SQL.squish)
            SELECT CASE
                   WHEN #{Gitlab::Database.pg_last_wal_receive_lsn}() = #{Gitlab::Database.pg_last_wal_receive_lsn}()
                    THEN 0
                   ELSE
                    EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())::INTEGER
                   END
                   AS replication_lag
          SQL
          .first
          .fetch('replication_lag')

        lag.present? ? lag.to_i : lag
      end

      def self.streaming_active?
        # Get a streaming status
        # This only works for Postgresql 9.6 and greater
        pid =
          ActiveRecord::Base.connection.select_values('
          SELECT pid FROM pg_stat_wal_receiver;')
          .first

        pid.to_i > 0
      end
    end
  end
end
