# frozen_string_literal: true

module API
  class PersonalAccessTokens
    class SelfRotation < ::API::Base
      include APIGuard

      feature_category :system_access

      helpers ::API::Helpers::PersonalAccessTokensHelpers

      allow_access_with_scope :api
      allow_access_with_scope :self_rotate

      before { authenticate! }

      resource :personal_access_tokens do
        desc 'Rotate a personal access token' do
          detail 'Rotates a personal access token by passing it to the API in a header'
          success code: 200, model: Entities::PersonalAccessTokenWithToken
          failure [
            { code: 400, message: 'Bad Request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 405, message: 'Method not allowed' }
          ]
          tags %w[personal_access_tokens]
        end
        params do
          optional :expires_at,
            type: Date,
            desc: "The expiration date of the token",
            documentation: { example: '2021-01-31' }
        end
        post 'self/rotate' do
          not_allowed! unless access_token.is_a? PersonalAccessToken

          new_token = rotate_token(access_token, declared_params)

          present new_token, with: Entities::PersonalAccessTokenWithToken
        end
      end
    end
  end
end
