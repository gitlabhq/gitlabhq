module SystemCheck
  module Geo
    class GeoDatabaseConfiguredCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo secondary database is correctly configured'
      set_skip_reason 'not a secondary node'

      WRONG_CONFIGURATION_MESSAGE = 'Check if you enabled the `geo_secondary_role` or `geo_postgresql` in the gitlab.rb config file.'.freeze
      UNHEALTHY_CONNECTION_MESSAGE = 'Check the tracking database configuration as the connection could not be established'.freeze
      NO_TABLES_MESSAGE = 'Run the tracking database migrations: gitlab-rake geo:db:migrate'.freeze

      def skip?
        !Gitlab::Geo.secondary?
      end

      def multi_check
        unless Gitlab::Geo.geo_database_configured?
          $stdout.puts 'no'.color(:red)

          try_fixing_it(WRONG_CONFIGURATION_MESSAGE)

          for_more_information('doc/gitlab-geo/database.md')

          return false
        end

        unless connection_healthy?
          $stdout.puts 'no'.color(:red)

          try_fixing_it(UNHEALTHY_CONNECTION_MESSAGE)

          for_more_information('doc/gitlab-geo/database.md')

          return false
        end

        unless tables_present?
          $stdout.puts 'no'.color(:red)

          try_fixing_it(NO_TABLES_MESSAGE)

          for_more_information('doc/gitlab-geo/database.md')

          return false
        end

        $stdout.puts 'yes'.color(:green)
        true
      end

      private

      def connection_healthy?
        ::Geo::TrackingBase.connection.active?
      end

      def tables_present?
        Gitlab::Geo::DatabaseTasks.with_geo_db { !ActiveRecord::Migrator.needs_migration? }
      end
    end
  end
end
