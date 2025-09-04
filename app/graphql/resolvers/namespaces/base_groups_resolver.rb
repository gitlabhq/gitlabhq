# frozen_string_literal: true

module Resolvers
  module Namespaces
    class BaseGroupsResolver < BaseResolver # rubocop:disable Graphql/ResolverType -- Child class defines the type
      include ResolvesGroups
      include Gitlab::Graphql::Authorize::AuthorizeResource

      # Sorting by storage size needs to be optimized. Restricted to admin-only to prevent abuse.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/556662
      ADMIN_RESTRICTED_SORTS = %w[storage_size_keyset_asc storage_size_keyset_desc].freeze

      argument :ids, [GraphQL::Types::ID],
        required: false,
        description: 'Filter groups by IDs.',
        prepare: ->(global_ids, _ctx) { GitlabSchema.parse_gids(global_ids, expected_type: ::Group).map(&:model_id) }

      argument :top_level_only, GraphQL::Types::Boolean,
        required: false,
        default_value: false,
        description: 'Only include top-level groups.'

      argument :owned_only, GraphQL::Types::Boolean,
        as: :owned,
        required: false,
        default_value: false,
        description: 'Only include groups where the current user has an owner role.'

      argument :search, GraphQL::Types::String,
        required: false,
        description: 'Search query for group name or group full path.'

      argument :sort, GraphQL::Types::String,
        required: false,
        description: "Sort order of results. Format: `<field_name>_<sort_direction>`, " \
          "for example: `id_desc` or `name_asc`",
        default_value: 'name_asc'

      argument :parent_path, GraphQL::Types::ID,
        required: false,
        description: 'Full path of the parent group.'

      argument :all_available, GraphQL::Types::Boolean,
        required: false,
        default_value: true,
        replace_null_with_default: true,
        description: <<~DESC
          When `true`, returns all accessible groups. When `false`, returns only groups where the user is a member.
          Unauthenticated requests always return all public groups. The `owned_only` argument takes precedence.
        DESC

      argument :marked_for_deletion_on, ::Types::DateType,
        required: false,
        description: 'Date when the group was marked for deletion.'

      argument :active, GraphQL::Types::Boolean,
        required: false,
        default_value: nil,
        description: 'When `nil` (default value), returns all groups. ' \
          'When `true`, returns only groups that are not pending deletion. ' \
          'When `false`, only returns groups that are pending deletion.'

      private

      def resolve_groups(parent_path: nil, **args)
        sanitized_args = sanitize_sort_args(args)
        sanitized_args[:parent] = find_authorized_parent!(parent_path) if parent_path
        sanitized_args[:organization] = Current.organization.id

        GroupsFinder
          .new(context[:current_user], sanitized_args)
          .execute
      end

      def find_authorized_parent!(path)
        group = Group.find_by_full_path(path)

        unless Ability.allowed?(current_user, :read_group, group)
          raise_resource_not_available_error! format(_('Could not find parent group with path %{path}'), path: path)
        end

        group
      end

      def sanitize_sort_args(args)
        return args unless ADMIN_RESTRICTED_SORTS.include?(args[:sort]) && !user_is_admin?

        args.except(:sort)
      end

      def user_is_admin?
        context[:current_user].present? && context[:current_user].can_admin_all_resources?
      end
    end
  end
end
