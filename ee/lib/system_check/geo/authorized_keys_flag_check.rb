module SystemCheck
  module Geo
    class AuthorizedKeysFlagCheck < ::SystemCheck::BaseCheck
      set_name 'GitLab configured to disable writing to authorized_keys file'

      def check?
        !Gitlab::CurrentSettings.current_application_settings.authorized_keys_enabled
      end

      def show_error
        try_fixing_it(
          "You need to disable `Write to authorized_keys file` in GitLab's Admin panel"
        )

        for_more_information(AuthorizedKeysCheck::AUTHORIZED_KEYS_DOCS)
      end
    end
  end
end
