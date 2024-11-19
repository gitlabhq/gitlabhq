# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Contacts
      class Update < Base
        graphql_name 'CustomerRelationsContactUpdate'

        argument :id, ::Types::GlobalIDType[::CustomerRelations::Contact],
          required: true,
          description: 'Global ID of the contact.'

        argument :organization_id, ::Types::GlobalIDType[::CustomerRelations::Organization],
          required: false,
          description: 'Organization of the contact.'

        argument :first_name, GraphQL::Types::String,
          required: false,
          description: 'First name of the contact.'

        argument :last_name, GraphQL::Types::String,
          required: false,
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

        argument :active, GraphQL::Types::Boolean,
          required: false,
          description: 'State of the contact.'

        def resolve(args)
          contact = ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(
            args.delete(:id),
            expected_type: ::CustomerRelations::Contact)
                                                 )
          raise_resource_not_available_error! unless contact

          group = contact.group
          authorize!(group)

          set_organization!(args)
          result = ::CustomerRelations::Contacts::UpdateService.new(
            group: group,
            current_user: current_user,
            params: args
          ).execute(contact)
          { contact: result.payload, errors: result.errors }
        end
      end
    end
  end
end
