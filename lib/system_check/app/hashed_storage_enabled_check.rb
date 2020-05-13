# frozen_string_literal: true

module SystemCheck
  module App
    class HashedStorageEnabledCheck < SystemCheck::BaseCheck
      set_name 'GitLab configured to store new projects in hashed storage?'

      def check?
        Gitlab::CurrentSettings.current_application_settings.hashed_storage_enabled
      end

      def show_error
        try_fixing_it(
          "Please enable the setting",
          "`Use hashed storage paths for newly created and renamed projects`",
          "in GitLab's Admin panel to avoid security issues and ensure data integrity."
        )

        for_more_information('doc/administration/repository_storage_types.md')
      end
    end
  end
end
