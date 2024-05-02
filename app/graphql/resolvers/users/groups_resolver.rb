# frozen_string_literal: true

module Resolvers
  module Users
    class GroupsResolver < BaseResolver
      include ResolvesGroups
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::GroupType.connection_type, null: true

      authorize :read_user_groups
      authorizes_object!

      argument :permission_scope,
        ::Types::PermissionTypes::GroupEnum,
        required: false,
        description: 'Filter by permissions the user has on groups.'
      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search by group name or path.'

      before_connection_authorization do |nodes, current_user|
        Preloaders::GroupPolicyPreloader.new(nodes, current_user).execute
      end

      private

      def resolve_groups(**args)
        ::Groups::UserGroupsFinder.new(current_user, object, args).execute
      end
    end
  end
end

Resolvers::Users::GroupsResolver.prepend_mod_with('Resolvers::Users::GroupsResolver')
