# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class TemplateType < BaseObject
      graphql_name 'CiTemplate'
      description 'GitLab CI/CD configuration template.'

      field :content, GraphQL::Types::String, null: false,
        description: 'Contents of the CI template.'
      field :name, GraphQL::Types::String, null: false,
        description: 'Name of the CI template.'
    end
  end
end
