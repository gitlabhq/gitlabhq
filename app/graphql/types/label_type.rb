# frozen_string_literal: true

module Types
  class LabelType < BaseObject
    graphql_name 'Label'

    connection_type_class Types::CountableConnectionType

    authorize :read_label

    field :color, GraphQL::Types::String, null: false,
                                          description: 'Background color of the label.'
    field :created_at, Types::TimeType, null: false,
                                        description: 'When this label was created.'
    field :description,
          GraphQL::Types::String,
          null: true,
          description: 'Description of the label (Markdown rendered as HTML for caching).'
    field :id, GraphQL::Types::ID, null: false,
                                   description: 'Label ID.'
    field :lock_on_merge, GraphQL::Types::Boolean, null: false,
                                                   description: 'Indicates this label is locked for merge requests ' \
                                                                'that have been merged.'
    field :text_color, GraphQL::Types::String, null: false,
                                               description: 'Text color of the label.'
    field :title, GraphQL::Types::String, null: false,
                                          description: 'Content of the label.'
    field :updated_at, Types::TimeType, null: false,
                                        description: 'When this label was last updated.'

    markdown_field :description_html, null: true
  end
end
