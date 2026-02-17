# frozen_string_literal: true

module Mutations
  # rubocop: disable Gitlab/BoundedContexts -- generic mutation for custom attribute
  module Groups
    module CustomAttributes
      class Set < BaseMutation
        graphql_name 'SetGroupCustomAttribute'
        description 'Creates or updates a custom attribute on a group. Only available to admins.'

        include Mutations::ResolvesGroup

        authorize :update_custom_attribute

        argument :group_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the group.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute.'

        argument :value, GraphQL::Types::String,
          required: true,
          description: 'Value of the custom attribute.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Custom attribute after mutation.'

        def resolve(group_path:, key:, value:)
          group = authorized_find!(full_path: group_path)

          result = ::CustomAttributes::UpsertService.new(group, current_user: current_user, key: key, value: value)
            .execute

          return { custom_attribute: nil, errors: Array(result.message) } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end

        private

        def find_object(full_path:)
          resolve_group(full_path: full_path)
        end
      end
    end
  end
  # rubocop: enable Gitlab/BoundedContexts
end
