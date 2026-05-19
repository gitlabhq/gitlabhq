# frozen_string_literal: true

module Projects
  module Settings
    class ServiceAccountsController < Projects::ApplicationController
      feature_category :user_management

      before_action :authorize_read_service_accounts!, only: [:index]

      # Explicitly defined to satisfy Rails/LexicallyScopedActionFilter.
      # Renders the default template (index.html.haml).
      def index; end

      private

      def authorize_read_service_accounts!
        render_404 unless can?(current_user, :read_service_account, project)
      end
    end
  end
end
