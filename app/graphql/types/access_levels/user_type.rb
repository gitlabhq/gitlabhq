# frozen_string_literal: true

module Types
  module AccessLevels
    class UserType < BaseObject
      graphql_name 'AccessLevelUser'
      description 'Representation of a GitLab user.'

      authorize :read_user

      present_using UserPresenter

      field :id,
        type: GraphQL::Types::ID,
        null: false,
        description: 'ID of the user.'

      field :username,
        type: GraphQL::Types::String,
        null: false,
        description: 'Username of the user.'

      field :name,
        type: GraphQL::Types::String,
        null: false,
        resolver_method: :redacted_name,
        description: <<~DESC
          Human-readable name of the user.
          Returns `****` if the user is a project bot and the requester does not have permission to view the project.
        DESC

      field :public_email,
        type: GraphQL::Types::String,
        null: true,
        description: "User's public email."

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: "URL of the user's avatar."

      field :web_url,
        type: GraphQL::Types::String,
        null: false,
        description: 'Web URL of the user.'

      field :web_path,
        type: GraphQL::Types::String,
        null: false,
        description: 'Web path of the user.'

      def redacted_name
        object.redacted_name(context[:current_user])
      end

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end
