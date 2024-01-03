# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::Organizations::OrganizationType.connection_type, null: true
      authorize :read_organization

      def resolve
        # For the Organization MVC, all the organizations are public. We need to change this to only accessible
        # organizations once we start supporting private organizations.
        # See https://gitlab.com/groups/gitlab-org/-/epics/10649.
        ::Organizations::Organization.all
      end
    end
  end
end
