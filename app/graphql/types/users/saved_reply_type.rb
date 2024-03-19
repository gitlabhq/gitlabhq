# frozen_string_literal: true

module Types
  module Users
    class SavedReplyType < ::Types::SavedReplyType
      graphql_name 'SavedReply'

      authorize :read_saved_replies

      field :id, Types::GlobalIDType[::Users::SavedReply],
        null: false,
        description: 'Global ID of the user saved reply.'
    end
  end
end
