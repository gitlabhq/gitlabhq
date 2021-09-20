# frozen_string_literal: true

module Resolvers
  module Users
    class GroupsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      type Types::GroupType.connection_type, null: true

      authorize :read_user_groups
      authorizes_object!

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search by group name or path.'
      argument :permission_scope,
               ::Types::PermissionTypes::GroupEnum,
               required: false,
               description: 'Filter by permissions the user has on groups.'

      before_connection_authorization do |nodes, current_user|
        Preloaders::UserMaxAccessLevelInGroupsPreloader.new(nodes, current_user).execute
      end

      def resolve_with_lookahead(**args)
        return unless Feature.enabled?(:paginatable_namespace_drop_down_for_project_creation, current_user, default_enabled: :yaml)

        apply_lookahead(Groups::UserGroupsFinder.new(current_user, object, args).execute)
      end

      private

      def preloads
        {
          path: [:route],
          full_path: [:route]
        }
      end
    end
  end
end

Resolvers::Users::GroupsResolver.prepend_mod_with('Resolvers::Users::GroupsResolver')
