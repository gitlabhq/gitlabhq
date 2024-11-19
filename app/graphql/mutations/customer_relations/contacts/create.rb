# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Contacts
      class Create < Base
        graphql_name 'CustomerRelationsContactCreate'

        include Gitlab::Graphql::Authorize::AuthorizeResource

        argument :group_id, ::Types::GlobalIDType[::Group],
          required: true,
          description: 'Group for the contact.'

        argument :organization_id, ::Types::GlobalIDType[::CustomerRelations::Organization],
          required: false,
          description: 'Organization for the contact.'

        argument :first_name, GraphQL::Types::String,
          required: true,
          description: 'First name of the contact.'

        argument :last_name, GraphQL::Types::String,
          required: true,
          description: 'Last name of the contact.'

        argument :phone, GraphQL::Types::String,
          required: false,
          description: 'Phone number of the contact.'

        argument :email, GraphQL::Types::String,
          required: false,
          description: 'Email address of the contact.'

        argument :description, GraphQL::Types::String,
          required: false,
          description: 'Description of or notes for the contact.'

        def resolve(args)
          group = authorized_find!(id: args[:group_id])

          set_organization!(args)
          result = ::CustomerRelations::Contacts::CreateService.new(
            group: group,
            current_user: current_user,
            params: args
          ).execute
          { contact: result.payload, errors: result.errors }
        end
      end
    end
  end
end
