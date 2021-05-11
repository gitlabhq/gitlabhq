# frozen_string_literal: true

module Projects
  module Security
    module ConfigurationHelper
      def security_upgrade_path
        'https://about.gitlab.com/pricing/'
      end
    end
  end
end

::Projects::Security::ConfigurationHelper.prepend_mod_with('Projects::Security::ConfigurationHelper')
