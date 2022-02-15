# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Contacts
      class Create < BaseMutation
        graphql_name 'CustomerRelationsContactCreate'

        include ResolvesIds
        include Gitlab::Graphql::Authorize::AuthorizeResource

        field :contact,
              Types::CustomerRelations::ContactType,
              null: true,
              description: 'Contact after the mutation.'

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

        authorize :admin_crm_contact

        def resolve(args)
          group = authorized_find!(id: args[:group_id])

          set_organization!(args)
          result = ::CustomerRelations::Contacts::CreateService.new(group: group, current_user: current_user, params: args).execute
          { contact: result.payload, errors: result.errors }
        end

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Group)
        end

        def set_organization!(args)
          return unless args[:organization_id]

          args[:organization_id] = resolve_ids(args[:organization_id], ::Types::GlobalIDType[::CustomerRelations::Organization])[0]
        end
      end
    end
  end
end
