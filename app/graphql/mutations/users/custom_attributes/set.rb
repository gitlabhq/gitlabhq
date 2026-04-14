# frozen_string_literal: true

module Mutations
  module Users
    module CustomAttributes
      class Set < BaseMutation
        graphql_name 'UserCustomAttributeSet'
        description 'Creates or updates a custom attribute on a user. Only available to admins.'

        authorize :update_custom_attribute

        argument :user_id, ::Types::GlobalIDType[::User],
          required: true,
          description: 'Global ID of the user.'

        argument :key, GraphQL::Types::String,
          required: true,
          description: 'Key of the custom attribute.'

        argument :value, GraphQL::Types::String,
          required: true,
          description: 'Value of the custom attribute.'

        field :custom_attribute, Types::CustomAttributeType,
          null: true,
          description: 'Custom attribute after mutation.'

        def resolve(user_id:, key:, value:)
          user = authorized_find!(id: user_id)

          result = ::CustomAttributes::UpsertService.new(user, current_user: current_user, key: key,
            value: value).execute

          return { custom_attribute: nil, errors: Array(result.message) } if result.error?

          { custom_attribute: result.payload[:custom_attribute], errors: [] }
        end
      end
    end
  end
end
