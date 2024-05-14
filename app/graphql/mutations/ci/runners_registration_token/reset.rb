# frozen_string_literal: true

module Mutations
  module Ci
    module RunnersRegistrationToken
      class Reset < BaseMutation
        graphql_name 'RunnersRegistrationTokenReset'

        authorize :update_runners_registration_token

        ScopeID = ::GraphQL::Types::ID

        argument :type, ::Types::Ci::RunnerTypeEnum,
          required: true,
          description: 'Scope of the object to reset the token for.'

        argument :id, ScopeID,
          required: false,
          description: 'ID of the project or group to reset the token for. Omit if resetting instance runner token.'

        field :token,
          GraphQL::Types::String,
          null: true,
          description: 'Runner token after mutation.'

        def resolve(type:, id: nil)
          scope = authorized_find!(type: type, id: id)
          new_token = reset_token(scope)

          {
            token: new_token,
            errors: errors_on_object(scope)
          }
        end

        private

        def find_object(type:, id: nil)
          case type
          when 'instance_type'
            raise Gitlab::Graphql::Errors::ArgumentError, "id must not be specified for '#{type}' scope" if id.present?

            ApplicationSetting.current
          when 'group_type'
            GitlabSchema.object_from_id(id, expected_type: ::Group)
          when 'project_type'
            GitlabSchema.object_from_id(id, expected_type: ::Project)
          end
        end

        def reset_token(scope)
          return unless scope

          result = ::Ci::Runners::ResetRegistrationTokenService.new(scope, current_user).execute
          result.payload[:new_registration_token] if result.success?
        end
      end
    end
  end
end
