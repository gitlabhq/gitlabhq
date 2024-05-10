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
        finder_params = args.merge(organization: organization)
        ::Organizations::GroupsFinder.new(context[:current_user], finder_params).execute
      end
    end
  end
end
