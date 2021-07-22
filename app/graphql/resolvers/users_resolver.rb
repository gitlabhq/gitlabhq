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
             description: 'Sort users by this criteria.',
             required: false,
             default_value: :created_desc

    argument :search, GraphQL::Types::String,
             required: false,
             description: "Query to search users by name, username, or primary email."

    argument :admins, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: 'Return only admin users.'

    def resolve(ids: nil, usernames: nil, sort: nil, search: nil, admins: nil)
      authorize!

      ::UsersFinder.new(context[:current_user], finder_params(ids, usernames, sort, search, admins)).execute
    end

    def ready?(**args)
      args = { ids: nil, usernames: nil }.merge!(args)

      return super if args.values.compact.blank?

      if args[:usernames]&.present? && args[:ids]&.present?
        raise Gitlab::Graphql::Errors::ArgumentError, 'Provide either a list of usernames or ids'
      end

      super
    end

    def authorize!
      Ability.allowed?(context[:current_user], :read_users_list) || raise_resource_not_available_error!
    end

    private

    def finder_params(ids, usernames, sort, search, admins)
      params = {}
      params[:sort] = sort if sort
      params[:username] = usernames if usernames
      params[:id] = parse_gids(ids) if ids
      params[:search] = search if search
      params[:admins] = admins if admins
      params
    end

    def parse_gids(gids)
      gids.map { |gid| GitlabSchema.parse_gid(gid, expected_type: ::User).model_id }
    end
  end
end
