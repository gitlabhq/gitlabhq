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
          description: 'The runner token after mutation.'

        def resolve(**args)
          {
            token: reset_token(**args),
            errors: []
          }
        end

        private

        def find_object(type:, **args)
          id = args[:id]

          case type
          when 'group_type'
            GitlabSchema.object_from_id(id, expected_type: ::Group)
          when 'project_type'
            GitlabSchema.object_from_id(id, expected_type: ::Project)
          end
        end

        def reset_token(type:, **args)
          id = args[:id]

          case type
          when 'instance_type'
            raise Gitlab::Graphql::Errors::ArgumentError, "id must not be specified for '#{type}' scope" if id.present?

            authorize!(:global)

            ApplicationSetting.current.reset_runners_registration_token!
            ApplicationSetting.current_without_cache.runners_registration_token
          when 'group_type', 'project_type'
            project_or_group = authorized_find!(type: type, id: id)
            project_or_group.reset_runners_token!
            project_or_group.runners_token
          end
        end
      end
    end
  end
end
