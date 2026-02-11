# frozen_string_literal: true

module Groups
  module DependencyProxy
    class ApplicationController < ::ApplicationController
      include ::JwtAuthenticatable

      # This allows auth_user to be set in the base ApplicationController
      alias_method :authenticated_user, :actor

      # We disable `authenticate_user!` since the `DependencyProxy::ApplicationController` performs auth using JWT token
      skip_before_action :authenticate_user!, raise: false

      prepend_before_action :authenticate_user_from_jwt_token!
      before_action :skip_session

      private

      def handle_personal_access_token(token)
        @personal_access_token = token
      end
    end
  end
end
