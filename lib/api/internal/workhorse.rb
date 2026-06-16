# frozen_string_literal: true

module API
  module Internal
    class Workhorse < ::API::Base
      before do
        verify_workhorse_api!
        content_type Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE
      end

      helpers do
        def request_authenticated?
          authenticator = Gitlab::Auth::RequestAuthenticator.new(request)
          return true if authenticator.find_authenticated_requester([:api])

          # Look up user from warden, ignoring the absence of a CSRF token. For
          # web users the CSRF token can be in the POST form data but Workhorse
          # does not propagate the form data to us.
          !!request.env['warden']&.authenticate
        end
      end

      namespace 'internal' do
        namespace 'workhorse' do
          route_setting :authorization, skip_granular_token_authorization: :workhorse_verification_auth
          post 'authorize_upload', feature_category: :not_owned do # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned -- Pre-existing: serves uploads across multiple feature areas (repo files, LFS, packages, registry, CI artifacts); no single owner.
            unauthorized! unless request_authenticated?

            status 200
            { TempPath: File.join(::Gitlab.config.uploads.storage_path, 'uploads/tmp') }
          end

          desc 'OAuth routing decision for Workhorse' do
            detail 'Workhorse calls this per OAuth request to decide whether to proxy ' \
              'to the IAM Auth Service or pass through to Rails, based on the ' \
              'proxy_oauth_requests_to_iam_service feature flag for the OAuth ' \
              'application identified by client_id. See gitlab-org/gitlab#594504. ' \
              'When client_id is missing or unknown, returns "rails" so Doorkeeper ' \
              'continues to own invalid_client error responses (RFC 6749 5.2).'
            success code: 200, message: 'Routing decision: "iam" or "rails"'
            tags %w[internal]
          end
          params do
            optional :client_id, type: String, limit: 255,
              desc: 'The OAuth application uid extracted by Workhorse from the OAuth request'
          end
          route_setting :authorization, skip_granular_token_authorization: :workhorse_verification_auth
          post 'oauth_routing', feature_category: :system_access do
            application = ::Authn::OauthApplication.by_uid(params[:client_id])
            destination = application&.iam_routing_enabled? ? 'iam' : 'rails'

            status 200
            { destination: destination }
          end
        end
      end
    end
  end
end
