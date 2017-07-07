module SystemCheck
  module Geo
    class GeoDatabaseConfiguredCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo secondary database is correctly configured'
      set_skip_reason 'not a secondary node'

      def skip?
        !Gitlab::Geo.secondary?
      end

      def check?
        Gitlab::Geo.geo_database_configured?
      end

      def show_error
        try_fixing_it(
          'Check if you enabled the `geo_secondary_role` or `geo_postgresql` in the gitlab.rb config file.'
        )

        for_more_information('doc/gitlab-geo/database.md')
      end
    end
  end
end
