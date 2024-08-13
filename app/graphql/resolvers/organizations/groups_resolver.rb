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
        ::Organizations::GroupsFinder.new(current_user, finder_params(args)).execute
      end

      def finder_params(args)
        args.merge(organization: organization)
      end
    end
  end
end

Resolvers::Organizations::GroupsResolver.prepend_mod
