# frozen_string_literal: true

module Types
  module WorkItems
    class CommentTemplatePathType < BaseObject # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
      graphql_name 'CommentTemplatePathType'

      field :href, GraphQL::Types::String,
        null: false,
        description: 'Management link to the comment template.'
      field :text, GraphQL::Types::String,
        null: false,
        description: 'Name of the comment template scope.'
    end
  end
end
