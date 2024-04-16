# frozen_string_literal: true

module Resolvers
  module Organizations
    class GroupsResolver < Resolvers::GroupsResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::GroupType.connection_type, null: true

      authorize :read_group

      private

      alias_method :organization, :object

      def resolve_groups(**args)
        ::Organizations::GroupsFinder.new(context[:current_user], finder_params(args)).execute
      end

      def finder_params(args)
        extra_args = if Feature.enabled?(:resolve_all_organization_groups, current_user)
                       { organization: organization }
                     else
                       { organization: organization, include_ancestors: false, all_available: false }
                     end

        super.merge(extra_args)
      end
    end
  end
end
