module SystemCheck
  module Geo
    class HTTPCloneEnabledCheck < ::SystemCheck::BaseCheck
      set_name 'HTTP/HTTPS repository cloning is enabled'

      def check?
        enabled_git_access_protocol.blank? || enabled_git_access_protocol == 'http'
      end

      def show_error
        try_fixing_it(
          'Enable HTTP/HTTPS repository cloning for Geo repository synchronization'
        )

        for_more_information('doc/gitlab-geo/README.md')
      end

      private

      def enabled_git_access_protocol
        Gitlab::CurrentSettings.current_application_settings.enabled_git_access_protocol
      end
    end
  end
end
