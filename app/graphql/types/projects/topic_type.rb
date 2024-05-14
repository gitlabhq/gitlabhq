# frozen_string_literal: true

module Types
  module Projects
    # rubocop: disable Graphql/AuthorizeTypes
    class TopicType < BaseObject
      graphql_name 'Topic'

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the topic.'

      field :name, GraphQL::Types::String, null: false,
        description: 'Name of the topic.'

      field :title, GraphQL::Types::String, null: false,
        method: :title_or_name,
        description: 'Title of the topic.'

      field :description, GraphQL::Types::String, null: true,
        description: 'Description of the topic.'

      field :avatar_url, GraphQL::Types::String, null: true,
        description: 'URL to avatar image file of the topic.'

      markdown_field :description_html, null: true

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
