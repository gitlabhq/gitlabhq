module SystemCheck
  module Geo
    class FdwSchemaUpToDateCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo tracking database Foreign Data Wrapper schema is up-to-date?'

      NOT_SECONDARY_NODE = 'not a secondary node'.freeze
      FDW_NOT_CONFIGURED = 'foreign data wrapper is not configured'.freeze

      def skip?
        unless Gitlab::Geo.secondary?
          self.skip_reason = NOT_SECONDARY_NODE

          return true
        end

        unless Gitlab::Geo::Fdw.enabled?
          self.skip_reason = FDW_NOT_CONFIGURED

          return true
        end

        false
      end

      def check?
        Gitlab::Geo::Fdw.fdw_up_to_date?
      end

      def show_error
        try_fixing_it(
          'Follow Geo setup instructions to configure secondary nodes with FDW support',
          'If you upgraded recently check for any new step required to enable FDW',
          'If you are using Omnibus GitLab try running:',
          'gitlab-ctl reconfigure',
          'If installing from source, try running:',
          'bundle exec rake geo:db:refresh_foreign_tables'
        )

        for_more_information('doc/gitlab-geo/database.md')
      end
    end
  end
end
