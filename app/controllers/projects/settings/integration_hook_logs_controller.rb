# frozen_string_literal: true

module Projects
  module Settings
    class IntegrationHookLogsController < Projects::HookLogsController
      extend Gitlab::Utils::Override

      before_action :integration, only: [:show, :retry]

      private

      override :after_retry_redirect_path
      def after_retry_redirect_path
        edit_project_settings_integration_path(@project, @integration)
      end

      def integration
        @integration ||= @project.find_or_initialize_integration(params[:integration_id])
      end

      override :hook
      def hook
        @hook ||= integration.try(:service_hook) || not_found
      end
    end
  end
end
