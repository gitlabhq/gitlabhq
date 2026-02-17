# frozen_string_literal: true

module Mutations
  module Projects
    module CustomAttributes
      class Delete < BaseMutation
        graphql_name 'DeleteProjectCustomAttribute'
        description 'Deletes a custom attribute from a project. Only available to admins.'

        include FindsProject

        authorize :delete_custom_attribute

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute to delete.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Deleted custom attribute.'

        def resolve(project_path:, key:)
          project = authorized_find!(project_path)

          result = ::CustomAttributes::DestroyService.new(project, current_user: current_user, key: key).execute

          return { custom_attribute: nil, errors: [result.message] } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end
      end
    end
  end
end
