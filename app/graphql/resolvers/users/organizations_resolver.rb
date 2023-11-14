# frozen_string_literal: true

module Resolvers
  module Users
    class OrganizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Organizations::OrganizationType.connection_type, null: true

      authorize :read_user_organizations
      authorizes_object!

      def resolve(**args)
        ::Organizations::UserOrganizationsFinder.new(current_user, object, args).execute
      end
    end
  end
end
