# frozen_string_literal: true

module Authn
  module Applications
    class DestroyService
      attr_reader :current_user, :request, :application

      def initialize(current_user, request, application)
        @current_user = current_user
        @request = request
        @application = application
      end

      def execute
        return error_response unless authorized?

        application.destroy

        application
      end

      private

      def authorized?
        Ability.allowed?(current_user, :delete_oauth_application, application)
      end

      def error_response
        application.errors.add(:base, _('Not authorized'))
        application
      end
    end
  end
end

Authn::Applications::DestroyService.prepend_mod_with('Authn::Applications::DestroyService')
