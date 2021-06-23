# frozen_string_literal: true

module Projects
  module Settings
    class IntegrationsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      layout "project_settings"

      feature_category :integrations

      def show
        @integrations = @project.find_or_initialize_integrations
      end
    end
  end
end
