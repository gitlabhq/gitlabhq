# frozen_string_literal: true

module Types
  class UserType < BaseObject
    graphql_name 'User'

    authorize :read_user

    present_using UserPresenter

    field :name, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :username, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :avatar_url, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
  end
end
