# frozen_string_literal: true

module Projects
  module Security
    module ConfigurationHelper
      def security_upgrade_path
        "https://#{ApplicationHelper.promo_host}/pricing/"
      end
    end
  end
end

::Projects::Security::ConfigurationHelper.prepend_mod_with('Projects::Security::ConfigurationHelper')
