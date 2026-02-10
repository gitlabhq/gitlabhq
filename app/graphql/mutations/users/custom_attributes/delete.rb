# frozen_string_literal: true

module Mutations
  module Users
    module CustomAttributes
      class Delete < BaseMutation
        graphql_name 'DeleteUserCustomAttribute'
        description 'Deletes a custom attribute from a user. Only available to admins.'

        authorize :delete_custom_attribute

        argument :user_id, ::Types::GlobalIDType[::User],
          required: true,
          description: 'Global ID of the user.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute to delete.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Deleted custom attribute.'

        def resolve(user_id:, key:)
          user = authorized_find!(id: user_id)

          result = ::CustomAttributes::DestroyService.new(user, current_user: current_user, key: key).execute

          return { custom_attribute: nil, errors: [result.message] } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end
      end
    end
  end
end
