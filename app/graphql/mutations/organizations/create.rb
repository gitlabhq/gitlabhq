# frozen_string_literal: true

module Mutations
  module Organizations
    class Create < Base
      graphql_name 'OrganizationCreate'

      authorize :create_organization

      argument :name, GraphQL::Types::String,
        required: true,
        description: 'Name for the organization.'

      argument :path, GraphQL::Types::String,
        required: true,
        description: 'Path for the organization.'

      def resolve(args)
        authorize!(:global)

        result = ::Organizations::CreateService.new(
          current_user: current_user,
          params: args
        ).execute

        { organization: result.payload[:organization], errors: result.errors }
      end
    end
  end
end
