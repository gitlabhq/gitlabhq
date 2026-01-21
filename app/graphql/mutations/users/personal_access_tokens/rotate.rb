# frozen_string_literal: true

module Mutations
  module Users
    module PersonalAccessTokens
      class Rotate < BaseMutation
        graphql_name 'PersonalAccessTokenRotate'
        description 'Rotate a specified personal access token.'

        field :token, GraphQL::Types::String,
          null: true,
          description: 'Created personal access token.'

        argument :id, ::Types::GlobalIDType[::PersonalAccessToken],
          required: true,
          description: 'Global ID of the personal access token that will be rotated.'

        argument :expires_at, GraphQL::Types::ISO8601Date,
          required: false,
          description: 'Expiration date of the token.'

        def resolve(id:, **args)
          if Feature.disabled?(:granular_personal_access_tokens, current_user)
            raise_resource_not_available_error! '`granular_personal_access_tokens` feature flag is disabled.'
          end

          token = find_object(id)
          raise_resource_not_available_error! unless current_user.can?(:manage_user_personal_access_token, token&.user)

          params = { expires_at: args[:expires_at] || token.expires_at }.compact
          result = ::PersonalAccessTokens::RotateService.new(current_user, token, nil, params).execute
          token = result.payload[:personal_access_token]

          return { errors: [result.message] } if result.error?

          { token: token.token, errors: [] }
        end

        private

        def find_object(id)
          ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(id, expected_type: ::PersonalAccessToken))
        end
      end
    end
  end
end
