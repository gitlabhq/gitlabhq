# frozen_string_literal: true

module Types
  class SavedReplyType < BaseObject
    connection_type_class Types::CountableConnectionType

    authorize :read_saved_replies

    field :content, GraphQL::Types::String,
      null: false,
      description: 'Content of the saved reply.'

    field :name, GraphQL::Types::String,
      null: false,
      description: 'Name of the saved reply.'
  end
end
