# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      feature_category :static_application_security_testing

      def show
        render_403 unless can?(current_user, :read_security_configuration, project)
      end
    end
  end
end

Projects::Security::ConfigurationController.prepend_if_ee('EE::Projects::Security::ConfigurationController')
