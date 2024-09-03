# frozen_string_literal: true

module API
  class WebCommits < ::API::Base
    GITALY_PUBLIC_KEY_CACHE_KEY = 'gitaly_public_key'
    GITALY_UNAVAILABLE = 'The git server, Gitaly, is not available at this time. Please contact your administrator.'
    PUBLIC_KEY_NOT_FOUND = 'Public key not found.'

    feature_category :source_code_management

    before { authenticate_non_get! }

    helpers do
      def gitaly_server
        @gitaly_server ||= Gitaly::Server.new(::Gitlab::GitalyClient.random_storage)
      end

      def server_signature_public_key
        gitaly_server.server_signature_public_key
      end

      def server_signature_error?
        gitaly_server.server_signature_error?
      end

      def handle_gitaly_unavailable
        render_api_error!(GITALY_UNAVAILABLE, :service_unavailable)
      end

      def handle_public_key_not_found
        render_api_error!(PUBLIC_KEY_NOT_FOUND, :not_found)
      end

      def cache_public_key
        Rails.cache.fetch(GITALY_PUBLIC_KEY_CACHE_KEY, expires_in: 1.hour.to_i, skip_nil: true) do
          { public_key: server_signature_public_key }
        end
      end
    end

    desc 'Get the public key for web commits' do
      detail 'This feature was introduced in GitLab 17.4.'
      success code: 200
      failure [
        { code: 503, message: GITALY_UNAVAILABLE },
        { code: 404, message: PUBLIC_KEY_NOT_FOUND }
      ]
    end

    get 'web_commits/public_key' do
      handle_gitaly_unavailable if server_signature_error?
      handle_public_key_not_found if server_signature_public_key.empty?

      cache_public_key
    end
  end
end
