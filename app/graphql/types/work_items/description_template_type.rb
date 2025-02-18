# frozen_string_literal: true

module Types
  module WorkItems
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization is done in the parent type
    class DescriptionTemplateType < BaseObject
      graphql_name 'WorkItemDescriptionTemplate'

      field :category, GraphQL::Types::String,
        description: 'Category of description template.', null: true, calls_gitaly: true
      field :content, GraphQL::Types::String,
        description: 'Content of Description Template.', null: true, calls_gitaly: true
      field :name, GraphQL::Types::String,
        description: 'Name of Description Template.', null: true, calls_gitaly: true
      field :project_id, GraphQL::Types::Int,
        description: 'ID of the description template project.', null: true, calls_gitaly: true
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
