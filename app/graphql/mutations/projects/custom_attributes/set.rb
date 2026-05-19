# frozen_string_literal: true

module Mutations
  module Projects
    module CustomAttributes
      class Set < BaseMutation
        graphql_name 'ProjectCustomAttributeSet'
        description 'Sets (creates or updates) a custom attribute on a project. Only available to admins.'

        include FindsProject

        authorize :update_custom_attribute
        authorize_granular_token permissions: :update_custom_attribute,
          boundary_argument: :project_path, boundary_type: :project

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute.'

        argument :value, GraphQL::Types::String,
          required: true,
          description: 'Value of the custom attribute.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Custom attribute after mutation.'

        def resolve(project_path:, key:, value:)
          project = authorized_find!(project_path)

          result = ::CustomAttributes::UpsertService.new(project, current_user: current_user, key: key, value: value)
            .execute

          return { custom_attribute: nil, errors: Array(result.message) } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end
      end
    end
  end
end
