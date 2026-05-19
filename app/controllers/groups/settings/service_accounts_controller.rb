# frozen_string_literal: true

module Groups
  module Settings
    class ServiceAccountsController < Groups::ApplicationController
      feature_category :user_management

      before_action :authorize_read_service_accounts!, only: [:index]

      # Explicitly defined to satisfy Rails/LexicallyScopedActionFilter.
      # Renders the default template (index.html.haml).
      def index; end

      private

      def authorize_read_service_accounts!
        render_404 unless can?(current_user, :read_service_account, group)
      end
    end
  end
end
