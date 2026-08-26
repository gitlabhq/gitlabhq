# frozen_string_literal: true

module Resolvers
  module Users
    class OrganizationsResolver < ::Resolvers::Organizations::OrganizationsResolver
      type Types::Organizations::OrganizationType.connection_type, null: true

      authorize :read_user_organizations
      authorizes_object!

      argument :solo_owned, GraphQL::Types::Boolean,
        required: false,
        description: 'When true, returns only organizations solely owned by the user.'

      def resolve(**args)
        ::Organizations::UserOrganizationsFinder.new(current_user, object, args).execute
      end
    end
  end
end
