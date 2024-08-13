# frozen_string_literal: true

module Resolvers
  class UsersResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::UserType.connection_type, null: true
    description 'Find Users'

    argument :ids, [GraphQL::Types::ID],
      required: false,
      description: 'List of user Global IDs.'

    argument :usernames, [GraphQL::Types::String], required: false,
      description: 'List of usernames.'

    argument :sort, Types::SortEnum,
      description: 'Sort users by the criteria.',
      required: false,
      default_value: :created_desc

    argument :search, GraphQL::Types::String,
      required: false,
      description: "Query to search users by name, username, or primary email."

    argument :admins, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Return only admin users.'

    argument :active, GraphQL::Types::Boolean,
      required: false,
      description: 'Filter by active users. When true, returns active users. When false, returns non-active users.'

    argument :humans, GraphQL::Types::Boolean,
      required: false,
      description: 'Filter by regular users. When true, returns only users that are not bot or internal users. ' \
        'When false, returns only users that are bot or internal users.'

    argument :group_id, ::Types::GlobalIDType[::Group],
      required: false,
      description: 'Return users member of a given group.'

    def resolve(ids: nil, usernames: nil, sort: nil, search: nil, admins: nil, humans: nil, active: nil, group_id: nil)
      authorize!(usernames)

      group = group_id ? find_authorized_group!(group_id) : nil

      ::UsersFinder.new(
        context[:current_user],
        finder_params(ids, usernames, sort, search, admins, group, humans, active)
      ).execute
    end

    def ready?(**args)
      args = { ids: nil, usernames: nil }.merge!(args)

      return super if args.values.compact.blank?

      if args[:usernames].present? && args[:ids].present?
        raise Gitlab::Graphql::Errors::ArgumentError, 'Provide either a list of usernames or ids'
      end

      super
    end

    def authorize!(usernames)
      raise_resource_not_available_error! unless context[:current_user].present?
    end

    private

    def finder_params(ids, usernames, sort, search, admins, group, humans, active)
      params = {}
      params[:sort] = sort if sort
      params[:username] = usernames if usernames
      params[:id] = parse_gids(ids) if ids
      params[:search] = search if search
      params[:admins] = admins if admins
      params[:humans] = humans == true
      params[:without_humans] = humans == false
      params[:active] = active == true
      params[:without_active] = active == false
      params[:group] = group if group
      params
    end

    def find_authorized_group!(group_id)
      group = GitlabSchema.find_by_gid(group_id).sync

      unless Ability.allowed?(current_user, :read_group, group)
        raise_resource_not_available_error! "Could not find a Group with ID #{group_id}"
      end

      group
    end

    def parse_gids(gids)
      gids.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::User).model_id }
    end
  end
end
