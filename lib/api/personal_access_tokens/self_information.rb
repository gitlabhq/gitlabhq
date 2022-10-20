# frozen_string_literal: true

module API
  class PersonalAccessTokens
    class SelfInformation < ::API::Base
      include APIGuard

      feature_category :authentication_and_authorization

      helpers ::API::Helpers::PersonalAccessTokensHelpers

      # As any token regardless of `scope` should be able to view/revoke itself
      # all available scopes are allowed for this API class.
      # Please be aware of the permissive scope when adding new endpoints to this class.
      allow_access_with_scope(Gitlab::Auth.all_available_scopes)

      before { authenticate! }

      resource :personal_access_tokens do
        get 'self' do
          present access_token, with: Entities::PersonalAccessToken
        end

        delete 'self' do
          revoke_token(access_token)
        end
      end
    end
  end
end
