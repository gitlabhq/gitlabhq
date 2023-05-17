# frozen_string_literal: true

module API
  class PersonalAccessTokens
    class SelfInformation < ::API::Base
      include APIGuard

      feature_category :system_access

      helpers ::API::Helpers::PersonalAccessTokensHelpers

      # As any token regardless of `scope` should be able to view/revoke itself
      # all available scopes are allowed for this API class.
      # Please be aware of the permissive scope when adding new endpoints to this class.
      allow_access_with_scope(Gitlab::Auth.all_available_scopes)

      before { authenticate! }

      resource :personal_access_tokens do
        desc "Get single personal access token" do
          detail 'Get the details of a personal access token by passing it to the API in a header'
          success code: 200, model: Entities::PersonalAccessToken
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[personal_access_tokens]
        end
        get 'self' do
          present access_token, with: Entities::PersonalAccessToken
        end

        desc "Revoke a personal access token" do
          detail 'Revoke a personal access token by passing it to the API in a header'
          success code: 204
          failure [
            { code: 400, message: 'Bad Request' }
          ]
          tags %w[personal_access_tokens]
        end

        delete 'self' do
          revoke_token(access_token)
        end
      end
    end
  end
end
