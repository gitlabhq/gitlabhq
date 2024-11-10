# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Organizations
      class Update < Mutations::BaseMutation
        graphql_name 'CustomerRelationsOrganizationUpdate'

        include ResolvesIds

        authorize :admin_crm_organization

        field :organization,
          Types::CustomerRelations::OrganizationType,
          null: false,
          description: 'Organization after the mutation.'

        argument :id, ::Types::GlobalIDType[::CustomerRelations::Organization],
          required: true,
          description: 'Global ID of the organization.'

        argument :name,
          GraphQL::Types::String,
          required: false,
          description: 'Name of the organization.'

        argument :default_rate,
          GraphQL::Types::Float,
          required: false,
          description: 'Standard billing rate for the organization.'

        argument :description,
          GraphQL::Types::String,
          required: false,
          description: 'Description of or notes for the organization.'

        argument :active, GraphQL::Types::Boolean,
          required: false,
          description: 'State of the organization.'

        def resolve(args)
          organization = ::Gitlab::Graphql::Lazy.force(
            GitlabSchema.object_from_id(args.delete(:id),
              expected_type: ::CustomerRelations::Organization)
          )
          raise_resource_not_available_error! unless organization

          group = organization.group
          authorize!(group)

          result = ::CustomerRelations::Organizations::UpdateService.new(
            group: group,
            current_user: current_user,
            params: args
          ).execute(organization)
          { organization: result.payload, errors: result.errors }
        end
      end
    end
  end
end
