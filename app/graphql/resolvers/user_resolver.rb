# frozen_string_literal: true

module Resolvers
  class UserResolver < BaseResolver
    description 'Retrieve a single user'

    type Types::UserType, null: true

    argument :id, Types::GlobalIDType[User],
             required: false,
             description: 'ID of the User.'

    argument :username, GraphQL::Types::String,
             required: false,
             description: 'Username of the User.'

    def ready?(id: nil, username: nil)
      unless id.present? ^ username.present?
        raise Gitlab::Graphql::Errors::ArgumentError, 'Provide either a single username or id'
      end

      super
    end

    def resolve(id: nil, username: nil)
      if id
        GitlabSchema.object_from_id(id, expected_type: User)
      else
        batch_load(username)
      end
    end

    private

    def batch_load(username)
      BatchLoader::GraphQL.for(username).batch do |usernames, loader|
        User.by_username(usernames).each do |user|
          loader.call(user.username, user)
        end
      end
    end
  end
end
