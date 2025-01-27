# frozen_string_literal: true

module API
  class ResourceAccessTokens
    class SelfRotation < ::API::Base
      include APIGuard

      feature_category :system_access

      helpers ::API::Helpers::PersonalAccessTokensHelpers
      helpers ::API::ResourceAccessTokens.helpers

      allow_access_with_scope :api
      allow_access_with_scope :self_rotate

      before { authenticate! }

      %w[project group].each do |source_type|
        resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Rotate a resource access token' do
            detail 'Rotates a resource access token by passing it to the API in a header'
            success code: 200, model: Entities::ResourceAccessTokenWithToken
            failure [
              { code: 400, message: 'Bad Request' },
              { code: 401, message: 'Unauthorized' },
              { code: 403, message: 'Forbidden' },
              { code: 405, message: 'Method not allowed' }
            ]
            tags %w[personal_access_tokens]
          end
          params do
            requires :id, type: String, desc: "The #{source_type} ID"
            optional :expires_at,
              type: Date,
              desc: "The expiration date of the token",
              documentation: { example: '2021-01-31' }
          end
          post ':id/access_tokens/self/rotate' do
            not_allowed! unless access_token.is_a? PersonalAccessToken
            not_allowed! unless current_user.project_bot?

            resource = find_source(source_type, params[:id])
            token = find_token(resource, access_token.id)

            unauthorized! unless token

            new_token = rotate_token(token, declared_params)

            present new_token, with: Entities::ResourceAccessTokenWithToken, resource: resource
          end
        end
      end
    end
  end
end
