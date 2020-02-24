# frozen_string_literal: true

module Projects
  module Settings
    class IntegrationsController < Projects::ApplicationController
      include ServiceParams

      before_action :authorize_admin_project!
      layout "project_settings"

      def show
        @services = @project.find_or_initialize_services(exceptions: service_exceptions)
      end

      private

      # Returns a list of services that should be hidden from the list
      def service_exceptions
        @project.disabled_services.dup
      end
    end
  end
end

Projects::Settings::IntegrationsController.prepend_if_ee('EE::Projects::Settings::IntegrationsController')
