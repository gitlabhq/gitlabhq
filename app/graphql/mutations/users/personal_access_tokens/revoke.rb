# frozen_string_literal: true

module Mutations
  module Users
    module PersonalAccessTokens
      class Revoke < BaseMutation
        graphql_name 'PersonalAccessTokenRevoke'
        description 'Revokes a specified personal access token.'

        authorize :revoke_token

        argument :id, ::Types::GlobalIDType[::PersonalAccessToken],
          required: true,
          description: 'Global ID of the personal access token that will be revoked.'

        def resolve(id:)
          if Feature.disabled?(:granular_personal_access_tokens, current_user)
            raise_resource_not_available_error! '`granular_personal_access_tokens` feature flag is disabled.'
          end

          token = authorized_find!(id: id)

          result = ::PersonalAccessTokens::RevokeService.new(current_user, token: token).execute
          result.success? ? { errors: [] } : { errors: [result.message] }
        end
      end
    end
  end
end
