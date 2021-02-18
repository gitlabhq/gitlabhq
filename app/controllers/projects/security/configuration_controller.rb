# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      feature_category :static_application_security_testing

      def show
        return render_404 unless feature_enabled?

        render_403 unless can?(current_user, :read_security_configuration, project)
      end

      private

      def feature_enabled?
        ::Feature.enabled?(:secure_security_and_compliance_configuration_page_on_ce, @project, default_enabled: :yaml)
      end
    end
  end
end

Projects::Security::ConfigurationController.prepend_if_ee('EE::Projects::Security::ConfigurationController')
