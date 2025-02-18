# frozen_string_literal: true

module Authz
  module Applications
    class ResetSecretService
      attr_reader :application, :current_user

      def initialize(application:, current_user:)
        @application = application
        @current_user = current_user
      end

      def execute
        return error(message: "#{current_user.name} cannot reset secret") unless can_reset_secret?(current_user)

        application.renew_secret

        return ServiceResponse.success if application.save

        error(message: "Couldn't save application")
      end

      private

      def error(message:)
        ServiceResponse.error(message: message)
      end

      def can_reset_secret?(current_user)
        current_user.can_admin_all_resources?
      end
    end
  end
end
