module SystemCheck
  module Geo
    class EnabledCheck < SystemCheck::BaseCheck
      set_name 'GitLab Geo is enabled'

      def check?
        Gitlab::Geo.enabled?
      end

      def show_error
        try_fixing_it(
          'Follow Geo setup instructions to configure primary and secondary nodes'
        )

        for_more_information('doc/gitlab-geo/README.md')
      end
    end
  end
end
