# frozen_string_literal: true

module Types
  class LabelType < BaseObject
    graphql_name 'Label'

    connection_type_class(Types::CountableConnectionType)

    authorize :read_label

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'Label ID.'
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the label (Markdown rendered as HTML for caching).'
    markdown_field :description_html, null: true
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Content of the label.'
    field :color, GraphQL::STRING_TYPE, null: false,
          description: 'Background color of the label.'
    field :text_color, GraphQL::STRING_TYPE, null: false,
          description: 'Text color of the label.'
    field :created_at, Types::TimeType, null: false,
          description: 'When this label was created.'
    field :updated_at, Types::TimeType, null: false,
          description: 'When this label was last updated.'
  end
end
