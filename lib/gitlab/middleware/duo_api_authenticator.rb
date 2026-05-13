# frozen_string_literal: true

module Gitlab
  module Middleware
    # DuoApiAuthenticator provides authentication support to JsonValidation middleware
    #   - verifies duo workflow API authentication before JSON body parsing occurs
    class DuoApiAuthenticator
      include Gitlab::Auth::AuthFinders

      attr_reader :current_request
      alias_method :request, :current_request

      DUO_WORKFLOW_AUTH_SETTING = {
        job_token_allowed: true,
        deploy_token_allowed: true
      }.freeze

      def self.verify!(request)
        new(request).verify!
      end

      def initialize(request)
        @current_request = ActionDispatch::Request.new(request.env)
      end

      def verify!
        find_user_from_sources.present?
      rescue Gitlab::Auth::AuthenticationError, StandardError => e
        Gitlab::AppLogger.info(
          message: "Duo Workflow API authentication failed",
          error: e.class.name,
          path: current_request.path
        )
        false
      end

      private

      # needed by Gitlab::Auth::AuthFinders
      def route_authentication_setting
        DUO_WORKFLOW_AUTH_SETTING
      end

      # each of these tokens are directly reference in Gitlab::Auth::AuthFinders
      # reflects auth flow in APIGuard#authenticate!
      def find_user_from_sources
        deploy_token_from_request ||
          find_user_from_bearer_token ||
          find_user_from_job_token
      end
    end
  end
end
