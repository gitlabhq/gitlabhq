# frozen_string_literal: true

module API
  module Authn
    class Userinfo < ::API::Base
      include APIGuard

      # It is possible that the OAuth Access token only carries the OIDC scopes (openid, email, ...),
      # and not :api/:read_api, so the global scope requirement in API::API
      # would otherwise reject every caller before the IamOauthToken check below runs.
      allow_access_with_scope [:openid, :api, :read_api]

      feature_category :system_access
      urgency :low

      before { authenticate! }

      resource :iam do
        desc 'Return the OIDC ID-token claims for the caller identified by an IAM OAuth token' do
          detail 'Authenticates exclusively via an IAM-issued OAuth JWT and returns the subset of ' \
            'OIDC claims documented as "Included in ID Token" in the OpenID Connect provider docs'
          success code: 200
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' }
          ]
          tags %w[authn]
        end
        # Removes from granular-PAT docs, since granular PATs are not supported for this endpoint
        route_setting :authorization, skip_granular_token_authorization: :iam_oauth_token_auth
        # A specific rate limit is intentionally left out here:
        # this endpoint is used in the IAM Auth flow that replaces Doorkeeper's ID-token issuance flow,
        # which has no dedicated rate limit of its own
        get :userinfo do
          # Doorkeeper access tokens and personal access tokens resolve successfully
          # through the standard bearer-token path above, but must not be accepted
          # here -- only an IAM-issued OAuth JWT identifies the caller for this claim set.
          unauthorized! unless access_token.is_a?(::Authn::Tokens::IamOauthToken)

          ::Authn::IamService::UserinfoClaimsBuilder.new(current_user).claims
        end
      end
    end
  end
end
