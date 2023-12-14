# frozen_string_literal: true

module Mutations
  module Organizations
    class Update < Base
      graphql_name 'OrganizationUpdate'

      authorize :admin_organization

      argument :id,
        Types::GlobalIDType[::Organizations::Organization],
        required: true,
        description: 'ID of the organization to mutate.'

      argument :name, GraphQL::Types::String,
        required: false,
        description: 'Name for the organization.'

      argument :path, GraphQL::Types::String,
        required: false,
        description: 'Path for the organization.'

      def resolve(id:, **args)
        organization = authorized_find!(id: id)

        result = ::Organizations::UpdateService.new(
          organization,
          current_user: current_user,
          params: args
        ).execute

        { organization: result.payload[:organization], errors: result.errors }
      end
    end
  end
end
