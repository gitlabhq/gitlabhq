# frozen_string_literal: true

module Resolvers
  class UserResolver < BaseResolver
    description 'Retrieve a single user'

    argument :id, GraphQL::ID_TYPE,
             required: false,
             description: 'ID of the User'

    argument :username, GraphQL::STRING_TYPE,
             required: false,
             description: 'Username of the User'

    def resolve(id: nil, username: nil)
      id_or_username = GitlabSchema.parse_gid(id, expected_type: ::User).model_id if id
      id_or_username ||= username

      ::UserFinder.new(id_or_username).find_by_id_or_username
    end

    def ready?(id: nil, username: nil)
      unless id.present? ^ username.present?
        raise Gitlab::Graphql::Errors::ArgumentError, 'Provide either a single username or id'
      end

      super
    end
  end
end
