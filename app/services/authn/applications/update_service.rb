# frozen_string_literal: true

module Authn
  module Applications
    class UpdateService
      IMMUTABLE_ATTRIBUTES = %w[redirect_uri confidential].freeze

      attr_reader :current_user, :request, :application, :params

      def initialize(current_user, request, application, params)
        @current_user = current_user
        @request = request
        @application = application
        @params = params
      end

      def execute
        return error_response unless authorized?

        application.update(params.except(*IMMUTABLE_ATTRIBUTES))

        application
      end

      private

      def authorized?
        Ability.allowed?(current_user, :update_oauth_application, application)
      end

      def error_response
        application.errors.add(:base, 'Not authorized')
        application
      end
    end
  end
end

Authn::Applications::UpdateService.prepend_mod_with('Authn::Applications::UpdateService')
