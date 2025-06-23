# frozen_string_literal: true

module Types
  module Namespaces
    module LinkPaths
      class CommentTemplateType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- parent is already authorized
        graphql_name 'CommentTemplatePath'

        field :href,
          GraphQL::Types::String,
          null: false,
          description: 'Path of the comment template.'

        field :text,
          GraphQL::Types::String,
          null: false,
          description: 'Text used on the template path.'
      end
    end
  end
end
