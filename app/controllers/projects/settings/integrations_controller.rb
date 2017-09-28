module Projects
  module Settings
    class IntegrationsController < Projects::ApplicationController
      include ServiceParams

      before_action :authorize_admin_project!
      layout "project_settings"

      def show
        @hooks = @project.hooks

        # Services
        @services = @project.find_or_initialize_services
      end

      def webhooks
        @hooks = @project.hooks
        @hook = ProjectHook.new
      end
    end
  end
end
