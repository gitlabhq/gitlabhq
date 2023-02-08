# frozen_string_literal: true

module Types
  class SavedReplyType < BaseObject
    graphql_name 'SavedReply'

    connection_type_class(Types::CountableConnectionType)

    authorize :read_saved_replies

    field :id, Types::GlobalIDType[::Users::SavedReply],
           null: false,
           description: 'Global ID of the saved reply.'

    field :content, GraphQL::Types::String,
          null: false,
          description: 'Content of the saved reply.'

    field :name, GraphQL::Types::String,
          null: false,
          description: 'Name of the saved reply.'
  end
end
