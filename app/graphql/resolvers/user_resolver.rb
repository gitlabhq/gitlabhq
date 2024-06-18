# frozen_string_literal: true

module Resolvers
  class UserResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    description 'Retrieve a single user'

    type Types::UserType, null: true

    argument :id, Types::GlobalIDType[User],
      required: false,
      description: 'ID of the User.'

    argument :username, GraphQL::Types::String,
      required: false,
      description: 'Username of the User.'

    validates exactly_one_of: [:id, :username]

    def resolve(id: nil, username: nil)
      authorize!

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
          loader.call(username, user)
        end
      end
    end

    def authorize!
      raise_resource_not_available_error! unless context[:current_user].present?
    end
  end
end
