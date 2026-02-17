# frozen_string_literal: true

module Mutations
  module Groups
    module CustomAttributes
      class Delete < BaseMutation
        graphql_name 'DeleteGroupCustomAttribute'
        description 'Deletes a custom attribute from a group. Only available to admins.'

        include Mutations::ResolvesGroup

        authorize :delete_custom_attribute

        argument :group_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the group.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute to delete.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Deleted custom attribute.'

        def resolve(group_path:, key:)
          group = authorized_find!(full_path: group_path)

          result = ::CustomAttributes::DestroyService.new(group, current_user: current_user, key: key).execute

          return { custom_attribute: nil, errors: [result.message] } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end

        private

        def find_object(full_path:)
          resolve_group(full_path: full_path)
        end
      end
    end
  end
end
