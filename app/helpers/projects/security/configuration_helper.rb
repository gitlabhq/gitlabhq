# frozen_string_literal: true

module Projects
  module Security
    module ConfigurationHelper
      def security_upgrade_path
        "https://#{ApplicationHelper.promo_host}/pricing/"
      end

      def vulnerability_training_docs_path
        help_page_path('user/application_security/vulnerabilities/index', anchor: 'enable-security-training-for-vulnerabilities')
      end
    end
  end
end

::Projects::Security::ConfigurationHelper.prepend_mod_with('Projects::Security::ConfigurationHelper')
