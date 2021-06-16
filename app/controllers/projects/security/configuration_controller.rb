# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      feature_category :static_application_security_testing

      before_action only: [:show] do
        push_frontend_feature_flag(:security_configuration_redesign, project, default_enabled: :yaml)
      end

      def show
        render_403 unless can?(current_user, :read_security_configuration, project)
      end
    end
  end
end

Projects::Security::ConfigurationController.prepend_mod_with('Projects::Security::ConfigurationController')
