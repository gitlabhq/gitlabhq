# frozen_string_literal: true

module Gitlab
  module Database
    # A class for reflecting upon a database and its settings, such as the
    # adapter name, PostgreSQL version, and the presence of tables or columns.
    class Reflection
      attr_reader :model

      def initialize(model)
        @model = model
        @version = nil
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
        model.connection_db_config.configuration_hash.with_indifferent_access
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

      # Check whether the underlying database is in read-only mode
      def db_read_only?
        pg_is_in_recovery =
          connection
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

      def cached_column_exists?(column_name)
        connection
          .schema_cache.columns_hash(model.table_name)
          .has_key?(column_name.to_s)
      end

      def cached_table_exists?
        exists? && connection.schema_cache.data_source_exists?(model.table_name)
      end

      def exists?
        # We can't _just_ check if `connection` raises an error, as it will
        # point to a `ConnectionProxy`, and obtaining those doesn't involve any
        # database queries. So instead we obtain the database version, which is
        # cached after the first call.
        connection.schema_cache.database_version
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

      def flavor
        {
          # Based on https://aws.amazon.com/premiumsupport/knowledge-center/aurora-version-number/
          'Amazon Aurora PostgreSQL' => { statement: 'SELECT AURORA_VERSION()', error: /PG::UndefinedFunction/ },
          # Based on https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.FeatureSupport.Extensions,
          # this is also available for both Aurora and RDS, so we need to check for the former first.
          'PostgreSQL on Amazon RDS' => { statement: 'SHOW rds.extensions', error: /PG::UndefinedObject/ },
          # Based on https://cloud.google.com/sql/docs/postgres/flags#postgres-c this should be specific
          # to Cloud SQL for PostgreSQL
          'Cloud SQL for PostgreSQL' => { statement: 'SHOW cloudsql.iam_authentication', error: /PG::UndefinedObject/ },
          # Based on
          #   - https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions
          #   - https://docs.microsoft.com/en-us/azure/postgresql/concepts-extensions
          # this should be available only for Azure Database for PostgreSQL - Flexible Server.
          'Azure Database for PostgreSQL - Flexible Server' => { statement: 'SHOW azure.extensions', error: /PG::UndefinedObject/ },
          # Based on
          #   - https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-servers
          #   - https://docs.microsoft.com/en-us/azure/postgresql/concepts-servers#managing-your-server
          # this database is present on both Flexible and Single server, so we should check the former first.
          'Azure Database for PostgreSQL - Single Server' => { statement: "SELECT datname FROM pg_database WHERE datname = 'azure_maintenance'" },
          # Based on
          #   - https://cloud.google.com/sql/docs/postgres/flags
          # running a query to detect flag names that begin with 'alloydb
          'AlloyDB for PostgreSQL' => { statement: "SELECT name FROM pg_settings WHERE name LIKE 'alloydb%'" }
        }.each do |flavor, conditions|
          return flavor if connection.execute(conditions[:statement]).to_a.present?
        rescue ActiveRecord::StatementInvalid => e
          raise if conditions[:error] && !e.message.match?(conditions[:error])
        end

        nil
      end

      private

      def connection
        model.connection
      end
    end
  end
end
