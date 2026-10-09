# frozen_string_literal: true

module Resolvers
  module Organizations
    class OrganizationUsersResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type Types::Organizations::OrganizationUserType.connection_type, null: true

      authorize :read_organization_user

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query for the name, username, or public email of the user. ' \
          'Partial matches require at least 3 characters.'

      alias_method :organization, :object

      def resolve_with_lookahead(search: nil)
        authorize!(object)
        check_search_rate_limit!(search)

        apply_lookahead(organization_users(search))
      end

      private

      def organization_users(search)
        ::Organizations::OrganizationUsersFinder
          .new(organization: organization, current_user: context[:current_user], search: search)
          .execute
      end

      # Shares the :autocomplete_users budget with Admin::Organizations::UsersController#invite_search.
      def check_search_rate_limit!(search)
        return if search.blank?

        throttled =
          if context[:request]
            ::Gitlab::ApplicationRateLimiter.throttled_request?(
              context[:request], current_user, :autocomplete_users, scope: { user: current_user }
            )
          else
            ::Gitlab::ApplicationRateLimiter.throttled?(:autocomplete_users, scope: { user: current_user })
          end

        return unless throttled

        raise_resource_not_available_error!(::Gitlab::ApplicationRateLimiter.throttled_error_message)
      end

      def preloads
        {
          user: [:user],
          badges: [{ user: [:identities] }]
        }
      end
    end
  end
end

Resolvers::Organizations::OrganizationUsersResolver.prepend_mod
