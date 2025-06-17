# frozen_string_literal: true

module Gitlab
  module Auth
    module EditorExtensions
      class LanguageServerClientVerifier
        def initialize(current_user:, request:)
          @current_user = current_user
          @request = request
        end

        def execute
          return ServiceResponse.success unless client.lsp_client? && enforce_language_server_version?

          return ServiceResponse.success if client.version >= minimum_version

          ServiceResponse.error(
            message: 'Requests from Editor Extension clients are restricted',
            payload: { client_version: client.version },
            reason: :instance_requires_newer_client
          )
        end

        private

        attr_reader :current_user, :request

        def client
          Gitlab::Auth::EditorExtensions::LanguageServerClient.new(
            client_version: request.headers['HTTP_X_GITLAB_LANGUAGE_SERVER_VERSION'],
            user_agent: request.headers['HTTP_USER_AGENT']
          )
        end

        def enforce_language_server_version?
          return false unless Gitlab::CurrentSettings.gitlab_dedicated_instance? ||
            Feature.enabled?(:enforce_language_server_version, current_user)

          Gitlab::CurrentSettings.enable_language_server_restrictions
        end

        def minimum_version
          Gem::Version.new(Gitlab::CurrentSettings.minimum_language_server_version)
        end
      end
    end
  end
end
