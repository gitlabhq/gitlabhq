# frozen_string_literal: true

module Types
  class LabelType < BaseObject
    graphql_name 'Label'

    authorize :read_label

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'Label ID'
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the label (Markdown rendered as HTML for caching)'
    markdown_field :description_html, null: true
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Content of the label'
    field :color, GraphQL::STRING_TYPE, null: false,
          description: 'Background color of the label'
    field :text_color, GraphQL::STRING_TYPE, null: false,
          description: 'Text color of the label'
  end
end
