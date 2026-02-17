# frozen_string_literal: true

module Mutations
  module Projects
    module CustomAttributes
      class Set < BaseMutation
        graphql_name 'ProjectCustomAttributeSet'
        description 'Sets (creates or updates) a custom attribute on a project. Only available to admins.'

        include FindsProject

        authorize :update_custom_attribute

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

        # rubocop: disable CodeReuse/ActiveRecord -- Custom attribute CRUD is simple enough to not need a service
        def resolve(project_path:, key:, value:)
          project = authorized_find!(project_path)

          custom_attribute = project.custom_attributes.find_or_initialize_by(key: key)
          custom_attribute.value = value

          if custom_attribute.save
            { custom_attribute: custom_attribute, errors: [] }
          else
            { custom_attribute: nil, errors: custom_attribute.errors.full_messages }
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
