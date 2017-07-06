module Gitlab
  module Geo
    class HealthCheck
      def self.perform_checks
        raise NotImplementedError.new('Geo is only compatible with PostgreSQL') unless Gitlab::Database.postgresql?

        return '' unless Gitlab::Geo.secondary?
        return 'The Geo database configuration file is missing.' unless Gitlab::Geo.geo_database_configured?
        return 'The Geo node has a database that is not configured for streaming replication with the primary node.' unless self.database_secondary?

        database_version  = self.get_database_version.to_i
        migration_version = self.get_migration_version.to_i

        if database_version != migration_version
          "Current Geo database version (#{database_version}) does not match latest migration (#{migration_version}).\n"\
          "You may have to run `gitlab-rake geo:db:migrate` as root on the secondary."
        else
          ''
        end
      rescue => e
        e.message
      end

      def self.db_migrate_path
        # Lazy initialisation so Rails.root will be defined
        @db_migrate_path ||= File.join(Rails.root, 'db', 'geo', 'migrate')
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

        Dir[File.join(self.db_migrate_path, "[0-9]*_*.rb")].each do |f|
          timestamp = f.scan(/0*([0-9]+)_[_.a-zA-Z0-9]*.rb/).first.first rescue -1

          if latest_migration.nil? || timestamp.to_i > latest_migration.to_i
            latest_migration = timestamp
          end
        end

        latest_migration
      end

      def self.database_secondary?
        raise NotImplementedError unless Gitlab::Database.postgresql?

        ActiveRecord::Base.connection.execute('SELECT pg_is_in_recovery()')
          .first
          .fetch('pg_is_in_recovery') == 't'
      end
    end
  end
end
