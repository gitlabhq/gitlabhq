# frozen_string_literal: true

module Resolvers
  module Users
    class GroupsResolver < BaseResolver
      include ResolvesGroups
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::GroupType.connection_type, null: true

      authorizes_object!

      argument :permission_scope,
        ::Types::PermissionTypes::GroupEnum,
        required: false,
        description: 'Filter by permissions the user has on groups.'
      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search by group name or path.'
      argument :solo_owned, GraphQL::Types::Boolean,
        required: false,
        description: 'When true, returns only groups in the current organization ' \
          'where the user is the sole owner.'
      argument :sort,
        Types::Namespaces::GroupSortEnum,
        required: false,
        description: 'Sort groups by given criteria.'

      validates mutually_exclusive: [:permission_scope, :solo_owned]

      before_connection_authorization do |nodes, current_user|
        Preloaders::GroupPolicyPreloader.new(nodes, current_user).execute
      end

      def self.authorized?(user, context)
        current_user = context[:current_user]

        super &&
          (current_user&.can?(:read_user_groups, user) ||
            current_user&.can?(:read_user_groups, context[:current_organization]))
      end

      private

      def resolve_groups(**args)
        args = { **args, organization: context[:current_organization] }
        ::Groups::UserGroupsFinder.new(current_user, object, args).execute
      end
    end
  end
end

Resolvers::Users::GroupsResolver.prepend_mod_with('Resolvers::Users::GroupsResolver')
