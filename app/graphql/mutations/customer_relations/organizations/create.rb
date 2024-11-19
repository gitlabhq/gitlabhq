# frozen_string_literal: true

module Mutations
  module CustomerRelations
    module Organizations
      class Create < BaseMutation
        graphql_name 'CustomerRelationsOrganizationCreate'

        include ResolvesIds
        include Gitlab::Graphql::Authorize::AuthorizeResource

        field :organization,
          Types::CustomerRelations::OrganizationType,
          null: true,
          description: 'Organization after the mutation.'

        argument :group_id, ::Types::GlobalIDType[::Group],
          required: true,
          description: 'Group for the organization.'

        argument :name,
          GraphQL::Types::String,
          required: true,
          description: 'Name of the organization.'

        argument :default_rate,
          GraphQL::Types::Float,
          required: false,
          description: 'Standard billing rate for the organization.'

        argument :description,
          GraphQL::Types::String,
          required: false,
          description: 'Description of or notes for the organization.'

        authorize :admin_crm_organization

        def resolve(args)
          group = authorized_find!(id: args[:group_id])

          result = ::CustomerRelations::Organizations::CreateService.new(
            group: group,
            current_user: current_user,
            params: args
          ).execute
          { organization: result.payload, errors: result.errors }
        end
      end
    end
  end
end
