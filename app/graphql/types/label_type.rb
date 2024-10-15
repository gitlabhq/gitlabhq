# frozen_string_literal: true

module Types
  class LabelType < BaseObject
    graphql_name 'Label'

    implements LabelInterface

    connection_type_class Types::CountableConnectionType

    authorize :read_label

    field :lock_on_merge, GraphQL::Types::Boolean, null: false,
      description: 'Indicates this label is locked for merge requests ' \
        'that have been merged.'

    markdown_field :description_html, null: true
  end
end
