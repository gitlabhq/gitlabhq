module SystemCheck
  module Geo
    class FdwEnabledCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo tracking database is configured to use Foreign Data Wrapper?'
      set_skip_reason 'not a secondary node'

      def skip?
        !Gitlab::Geo.secondary?
      end

      def check?
        Gitlab::Geo::Fdw.enabled?
      end

      def show_error
        try_fixing_it(
          'Follow Geo setup instructions to configure secondary nodes with FDW support',
          'If you upgraded recently check for any new step required to enable FDW'
        )

        for_more_information('doc/gitlab-geo/database.md')
      end
    end
  end
end
