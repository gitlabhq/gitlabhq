# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationsResolver < BaseResolver
      type Types::Organizations::OrganizationType.connection_type, null: true

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query, which can be for the organization name or a path.'

      def resolve(**args)
        ::Organizations::OrganizationsFinder
          .new(context[:current_user], args)
          .execute
      end
    end
  end
end
